// app/javascript/chat/call_session.js
// Shared plumbing for voice + video calls: the CallChannel subscription,
// WebRTC peer connection setup, the audio call-bar, the video overlay,
// ringtone, and teardown.
//
// Call type travels inside the "call-offer" signal payload as
// { sdp, video: true|false } so the receiving side knows whether to render
// the audio call-bar or the video overlay before it even answers.
//
// NOTE (open investigation): if CallChannel's `subscribed` never appears to
// fire server-side, confirm the client is actually reaching the channel at
// all (check the Rails log for a CallChannel#subscribed line per page load)
// before assuming this client code is at fault — this has previously been
// traced back to broadcast stream name mismatches on the ChatroomChannel,
// so it's worth ruling the same category of bug out here too.

import { messagesContainer, csrfToken } from "./dom_utils";
import { createConsumer } from "@rails/actioncable";

const CALL_TIMEOUT_MS = 30000;
const ICE_SERVERS = [
  { urls: "stun:stun.l.google.com:19302" },
  { urls: "stun:stun1.l.google.com:19302" },
];

let callSubscription = null;
let peerConnection = null;
let localStream = null;
let callState = "idle"; // idle | calling | ringing | connected
let callType = "audio"; // audio | video
let callTimerInterval = null;
let callSeconds = 0;
let callTimeoutHandle = null;
let pendingOffer = null; // { sdp, video }
let isMuted = false;
let isCameraOff = false;
let ringAudioCtx = null;
let ringOscInterval = null;
let offerHandler = null; // set by incoming_call.js via initCallChannel()

// ---- state accessors ----

export function currentCallState() {
  return callState;
}

export function setCallState(state) {
  callState = state;
}

export function currentCallType() {
  return callType;
}

export function setCallType(type) {
  callType = type === "video" ? "video" : "audio";
}

export function getPeerConnection() {
  return peerConnection;
}

export function getLocalStream() {
  return localStream;
}

export function getPendingOffer() {
  return pendingOffer;
}

export function setPendingOffer(offer) {
  pendingOffer = offer;
}

// ---- ringtone ----

export function playRingtone() {
  stopRingtone();
  try {
    ringAudioCtx = new (window.AudioContext || window.webkitAudioContext)();
  } catch (e) {
    return;
  }

  function ringOnce() {
    if (!ringAudioCtx) return;
    const now = ringAudioCtx.currentTime;
    [0, 0.3].forEach((offset) => {
      const osc = ringAudioCtx.createOscillator();
      const gain = ringAudioCtx.createGain();
      osc.frequency.value = 480;
      osc.type = "sine";
      gain.gain.setValueAtTime(0.0001, now + offset);
      gain.gain.exponentialRampToValueAtTime(0.15, now + offset + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + offset + 0.28);
      osc.connect(gain);
      gain.connect(ringAudioCtx.destination);
      osc.start(now + offset);
      osc.stop(now + offset + 0.3);
    });
  }

  ringOnce();
  ringOscInterval = setInterval(ringOnce, 2000);
}

export function stopRingtone() {
  if (ringOscInterval) {
    clearInterval(ringOscInterval);
    ringOscInterval = null;
  }
  if (ringAudioCtx) {
    ringAudioCtx.close().catch(() => {});
    ringAudioCtx = null;
  }
}

// ---- CallChannel signaling ----

// handlers: { onOffer(payload) } — called when a call-offer arrives while
// idle. Incoming-call UI registers this; outgoing calls don't need it.
export function initCallChannel(handlers = {}) {
  offerHandler = handlers.onOffer || null;

  const container = messagesContainer();
  if (!container) return;
  const chatroomId = container.dataset.chatroomId;
  const currentUserId = container.dataset.currentUserId;

  if (callSubscription) {
    callSubscription.unsubscribe();
    callSubscription = null;
  }

  const consumer = createConsumer("/cable");
  callSubscription = consumer.subscriptions.create(
    { channel: "CallChannel", chatroom_id: chatroomId },
    {
      received(data) {
        if (Number(data.sender_id) === Number(currentUserId)) return;
        console.log("Incoming call signal:", data);
        handleSignal(data);
      },
    }
  );
}

export function sendSignal(type, payload) {
  if (!callSubscription) return;
  callSubscription.perform("signal", { type, payload });
}

// Turns whatever came back over the wire into a consistent
// { sdp: RTCSessionDescriptionInit, video: boolean } shape.
//
// Expected shape (current client): payload = { sdp: {type, sdp}, video }
// Tolerated shape (legacy client / server that stripped the wrapper):
//   payload = {type, sdp} directly, i.e. the raw offer with no wrapper.
//
// If neither shape yields a usable { type, sdp } pair, returns null so the
// caller can fail loudly instead of crashing inside RTCSessionDescription.
function normalizeOfferPayload(payload) {
  if (!payload || typeof payload !== "object") return null;

  const looksLikeWrapped = payload.sdp && typeof payload.sdp === "object";
  const rawSdp = looksLikeWrapped ? payload.sdp : payload;
  const video = !!payload.video;

  if (!rawSdp || typeof rawSdp.type !== "string" || typeof rawSdp.sdp !== "string") {
    console.error("[CallChannel] Received an unusable call-offer payload:", payload);
    return null;
  }

  return { sdp: rawSdp, video };
}

async function handleSignal(data) {
  if (data.type === "call-offer") {
    if (callState !== "idle") {
      sendSignal("call-busy", {});
      return;
    }

    const normalized = normalizeOfferPayload(data.payload);
    if (!normalized) {
      // Malformed offer — bail out instead of leaving the caller ringing
      // forever with a client that's about to throw.
      sendSignal("call-decline", {});
      return;
    }

    pendingOffer = normalized;
    setCallType(normalized.video ? "video" : "audio");
    callState = "ringing";
    if (offerHandler) offerHandler(normalized);
  } else if (data.type === "call-answer") {
    if (peerConnection) await peerConnection.setRemoteDescription(new RTCSessionDescription(data.payload));
    onCallConnected();
  } else if (data.type === "ice-candidate") {
    if (peerConnection) {
      try {
        await peerConnection.addIceCandidate(new RTCIceCandidate(data.payload));
      } catch (err) {
        console.error("ICE add error:", err);
      }
    }
  } else if (["call-end", "call-busy", "call-decline"].includes(data.type)) {
    teardownCall({ notifyRemote: false });
  }
}

// ---- peer connection ----

export function createPeerConnection() {
  const pc = new RTCPeerConnection({ iceServers: ICE_SERVERS });

  pc.onicecandidate = (e) => {
    if (e.candidate) sendSignal("ice-candidate", e.candidate);
  };

  pc.ontrack = (e) => {
    if (callType === "video") {
      const remoteVideo = document.getElementById("remote-video");
      if (remoteVideo) remoteVideo.srcObject = e.streams[0];
    } else {
      let remoteAudio = document.getElementById("remote-audio");
      if (!remoteAudio) {
        remoteAudio = document.createElement("audio");
        remoteAudio.id = "remote-audio";
        remoteAudio.autoplay = true;
        document.body.appendChild(remoteAudio);
      }
      remoteAudio.srcObject = e.streams[0];
    }
  };

  pc.onconnectionstatechange = () => {
    if (["disconnected", "failed", "closed"].includes(pc.connectionState) && callState !== "idle") {
      teardownCall({ notifyRemote: false });
    }
  };

  peerConnection = pc;
  return pc;
}

// video: true requests camera + mic, false requests mic only
export async function acquireMediaStream(video) {
  localStream = await navigator.mediaDevices.getUserMedia({
    audio: true,
    video: video ? { facingMode: "user" } : false,
  });
  return localStream;
}

// Back-compat alias for any existing audio-only call sites.
export async function acquireMicrophone() {
  return acquireMediaStream(false);
}

export function attachLocalTracks(pc, stream) {
  stream.getTracks().forEach((track) => pc.addTrack(track, stream));
}

export function attachLocalPreview(stream) {
  const localVideo = document.getElementById("local-video");
  if (!localVideo) return;
  if (stream.getVideoTracks().length === 0) {
    localVideo.classList.add("hidden");
    return;
  }
  localVideo.srcObject = stream;
  localVideo.classList.remove("hidden");
}

function clearLocalPreview() {
  const localVideo = document.getElementById("local-video");
  if (!localVideo) return;
  localVideo.srcObject = null;
  localVideo.classList.add("hidden");
}

function clearRemoteVideo() {
  const remoteVideo = document.getElementById("remote-video");
  if (remoteVideo) remoteVideo.srcObject = null;
}

// ---- audio call bar ----

export function showCallBar(status, { showTimer, showMute } = {}) {
  const bar = document.getElementById("call-bar");
  const statusEl = document.getElementById("call-bar-status");
  const timerEl = document.getElementById("call-timer");
  const muteBtn = document.getElementById("call-mute-btn");

  bar.classList.remove("hidden");
  bar.classList.add("flex");
  statusEl.textContent = status;
  timerEl.classList.toggle("hidden", !showTimer);
  muteBtn.classList.toggle("hidden", !showMute);
}

export function hideCallBar() {
  const bar = document.getElementById("call-bar");
  bar.classList.add("hidden");
  bar.classList.remove("flex");
}

// ---- video call overlay ----

export function showVideoCallUI(status, { showTimer } = {}) {
  const overlay = document.getElementById("video-call-overlay");
  const statusEl = document.getElementById("video-call-status");
  const timerEl = document.getElementById("video-call-timer");
  if (!overlay) return;

  overlay.classList.remove("hidden");
  overlay.classList.add("flex");
  if (statusEl) statusEl.textContent = status;
  if (timerEl) timerEl.classList.toggle("hidden", !showTimer);
}

export function hideVideoCallUI() {
  const overlay = document.getElementById("video-call-overlay");
  if (!overlay) return;
  overlay.classList.add("hidden");
  overlay.classList.remove("flex");
  clearLocalPreview();
  clearRemoteVideo();
}

function startCallTimer() {
  callSeconds = 0;
  const timerEl = document.getElementById("call-timer");
  const videoTimerEl = document.getElementById("video-call-timer");
  if (timerEl) timerEl.textContent = "00:00";
  if (videoTimerEl) videoTimerEl.textContent = "00:00";
  callTimerInterval = setInterval(() => {
    callSeconds++;
    const m = String(Math.floor(callSeconds / 60)).padStart(2, "0");
    const s = String(callSeconds % 60).padStart(2, "0");
    if (timerEl) timerEl.textContent = `${m}:${s}`;
    if (videoTimerEl) videoTimerEl.textContent = `${m}:${s}`;
  }, 1000);
}

function stopCallTimer() {
  if (callTimerInterval) {
    clearInterval(callTimerInterval);
    callTimerInterval = null;
  }
}

export function onCallConnected() {
  clearTimeout(callTimeoutHandle);
  stopRingtone();
  callState = "connected";
  const name = document.getElementById("other-member-name")?.textContent || "call";

  if (callType === "video") {
    showVideoCallUI(name, { showTimer: true });
  } else {
    showCallBar(`In call with ${name}`, { showTimer: true, showMute: true });
  }
  startCallTimer();
}

export function scheduleCallTimeout(onTimeout) {
  clearTimeout(callTimeoutHandle);
  callTimeoutHandle = setTimeout(onTimeout, CALL_TIMEOUT_MS);
}

export function clearCallTimeout() {
  clearTimeout(callTimeoutHandle);
}

async function recordMissedCall() {
  const container = messagesContainer();
  const chatroomId = container?.dataset.chatroomId;
  const recipientId =
    document.getElementById("voice-call-btn")?.dataset.recipientId ||
    document.getElementById("video-call-btn")?.dataset.recipientId;
  if (!chatroomId || !recipientId) return;

  try {
    await fetch(`/chatrooms/${chatroomId}/calls`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken(),
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ recipient_id: recipientId }),
    });
  } catch (err) {
    console.error("Missed call log error:", err);
  }
}

function resetMuteIcon() {
  document.getElementById("mic-on-icon")?.classList.remove("hidden");
  document.getElementById("mic-off-icon")?.classList.add("hidden");
  document.getElementById("video-mic-on-icon")?.classList.remove("hidden");
  document.getElementById("video-mic-off-icon")?.classList.add("hidden");
}

function resetCameraIcon() {
  document.getElementById("camera-on-icon")?.classList.remove("hidden");
  document.getElementById("camera-off-icon")?.classList.add("hidden");
}

export function toggleMute() {
  if (!localStream) return;
  isMuted = !isMuted;
  localStream.getAudioTracks().forEach((t) => {
    t.enabled = !isMuted;
  });
  document.getElementById("mic-on-icon")?.classList.toggle("hidden", isMuted);
  document.getElementById("mic-off-icon")?.classList.toggle("hidden", !isMuted);
  document.getElementById("video-mic-on-icon")?.classList.toggle("hidden", isMuted);
  document.getElementById("video-mic-off-icon")?.classList.toggle("hidden", !isMuted);
}

export function toggleCamera() {
  if (!localStream) return;
  const videoTracks = localStream.getVideoTracks();
  if (videoTracks.length === 0) return;

  isCameraOff = !isCameraOff;
  videoTracks.forEach((t) => {
    t.enabled = !isCameraOff;
  });
  document.getElementById("camera-on-icon")?.classList.toggle("hidden", isCameraOff);
  document.getElementById("camera-off-icon")?.classList.toggle("hidden", !isCameraOff);
}

export function teardownCall({ notifyRemote, signalType } = {}) {
  const wasCalling = callState === "calling";
  const wasConnected = callState === "connected";

  clearTimeout(callTimeoutHandle);
  stopRingtone();
  stopCallTimer();
  hideCallBar();
  hideVideoCallUI();

  if (peerConnection) {
    peerConnection.close();
    peerConnection = null;
  }
  if (localStream) {
    localStream.getTracks().forEach((t) => t.stop());
    localStream = null;
  }
  document.getElementById("remote-audio")?.remove();

  if (notifyRemote) sendSignal(signalType || "call-end", {});
  if (wasCalling && !wasConnected) recordMissedCall();

  isMuted = false;
  isCameraOff = false;
  resetMuteIcon();
  resetCameraIcon();
  pendingOffer = null;
  callState = "idle";
  callType = "audio";
}

export function initCallControls() {
  document
    .getElementById("call-hangup-btn")
    ?.addEventListener("click", () => teardownCall({ notifyRemote: true, signalType: "call-end" }));
  document.getElementById("call-mute-btn")?.addEventListener("click", toggleMute);

  document
    .getElementById("video-hangup-btn")
    ?.addEventListener("click", () => teardownCall({ notifyRemote: true, signalType: "call-end" }));
  document.getElementById("video-mute-btn")?.addEventListener("click", toggleMute);
  document.getElementById("video-camera-toggle-btn")?.addEventListener("click", toggleCamera);
}
