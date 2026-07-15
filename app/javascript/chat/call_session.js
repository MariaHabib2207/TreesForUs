// app/javascript/chat/call_session.js
// Shared plumbing for voice + video calls: the CallChannel subscription
// (scoped to the signed-in user, not any particular chatroom), WebRTC peer
// connection setup, the audio call-bar, the video overlay, ringtone, and
// teardown. Works from any page because the call UI lives in a
// data-turbo-permanent partial in the layout, and the subscription reads
// the user id off <body data-current-user-id>.
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
import { initVideoLayout, resetVideoLayout, setLocalMirrored } from "./video_layout";

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
let currentFacingMode = "user"; // "user" (front) | "environment" (back)
let isFlippingCamera = false; // guards against double-taps mid-swap
let isOutgoingCall = false; // true only on the browser that placed the call —
                             // that's the one that logs the Call record, so a
                             // single call never produces two log rows.

// ---- screen share state ----
// screenStream: the MediaStream from getDisplayMedia(), kept only so we can
// stop() its tracks on exit (releases the "sharing your screen" browser UI).
// cameraVideoTrack: the ORIGINAL camera track, stashed while sharing so
// stopScreenShare() can hand it back to both the peer connection sender and
// the local preview. It is never stopped while stashed — only swapped out
// and back in — so the camera doesn't need to be re-acquired afterward.
//
// remoteIsScreenSharing: mirrors the OTHER participant's sharing state,
// driven entirely by "screen-share-start"/"screen-share-stop" signals over
// CallChannel. This is what enforces "only one person shares at a time" —
// we never inspect media tracks to decide this, only the signal.
let isScreenSharing = false;
let screenStream = null;
let cameraVideoTrack = null;
let remoteIsScreenSharing = false;

// Identity of the call in progress, independent of whatever page the user
// is currently on. Set by outgoing_call.js when placing a call, or derived
// from the incoming offer's payload when receiving one. Every signal sent
// after a call is established reads recipient_id/chatroom_id from here.
let activeChatroomId = null;
let activeRecipientId = null;
let activeCallerName = null;
let activeCallerAvatarUrl = null;

export function setActiveCall({ chatroomId, recipientId, callerName, callerAvatarUrl } = {}) {
  if (chatroomId !== undefined) activeChatroomId = chatroomId;
  if (recipientId !== undefined) activeRecipientId = recipientId;
  if (callerName !== undefined) activeCallerName = callerName;
  if (callerAvatarUrl !== undefined) activeCallerAvatarUrl = callerAvatarUrl;
}

export function getActiveCall() {
  return {
    chatroomId: activeChatroomId,
    recipientId: activeRecipientId,
    callerName: activeCallerName,
    callerAvatarUrl: activeCallerAvatarUrl,
  };
}

export function setOutgoingCall(value) {
  isOutgoingCall = !!value;
}

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

export function isCurrentlyScreenSharing() {
  return isScreenSharing;
}

// Best-effort name for whoever's on the other end, for both call
// directions: incoming calls capture it from the offer payload
// (activeCallerName); outgoing calls read it off the chatroom page's
// #other-member-name element (same element outgoing_call.js already uses
// for its "Calling {name}…" status text).
function getOtherParticipantName() {
  return (
    activeCallerName ||
    document.getElementById("other-member-name")?.textContent?.trim() ||
    "The other participant"
  );
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

// Subscribes once per full page load, identified by the signed-in user
// (from <body data-current-user-id>) rather than any chatroom. Safe to call
// from any page; safe to call more than once (no-ops if already subscribed).
//
// handlers: { onOffer(payload) } — called when a call-offer arrives while
// idle. Incoming-call UI registers this; outgoing calls don't need it.
export function initCallChannel(handlers = {}) {
  offerHandler = handlers.onOffer || null;

  const currentUserId = document.body.dataset.currentUserId;
  if (!currentUserId) return; // not signed in

  if (callSubscription) return; // already subscribed — don't double-subscribe

  const consumer = createConsumer("/cable");
  callSubscription = consumer.subscriptions.create(
    { channel: "CallChannel" },
    {
      received(data) {
        if (Number(data.sender_id) === Number(currentUserId)) return;
        console.log("Incoming call signal:", data);
        handleSignal(data);
      },
    }
  );
}

// Every signal now needs to say who it's for, since the channel is scoped
// to the sender's own connection, not a shared chatroom stream.
export function sendSignal(type, payload) {
  if (!callSubscription) return;
  if (!activeRecipientId) {
    console.error("[CallChannel] sendSignal called with no active recipient");
    return;
  }
  callSubscription.perform("signal", {
    type,
    payload,
    recipient_id: activeRecipientId,
    chatroom_id: activeChatroomId,
  });
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
      // Need a recipient to decline back to — use the sender of this offer.
      setActiveCall({ recipientId: data.sender_id, chatroomId: data.chatroom_id });
      sendSignal("call-busy", {});
      return;
    }

    const normalized = normalizeOfferPayload(data.payload);
    if (!normalized) {
      setActiveCall({ recipientId: data.sender_id, chatroomId: data.chatroom_id });
      sendSignal("call-decline", {});
      return;
    }

    // Capture who's calling and from which chatroom BEFORE invoking the
    // handler, so incoming_call.js can render the caller's name/avatar
    // without needing to be on that chatroom's page.
    setActiveCall({
      chatroomId: data.chatroom_id,
      recipientId: data.sender_id,
      callerName: data.sender_name || "Someone",
      callerAvatarUrl: data.sender_avatar_url || null,
    });

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
  } else if (data.type === "screen-share-start") {
    remoteIsScreenSharing = true;
    updateScreenShareUI();
    showScreenShareBanner(`${getOtherParticipantName()} is sharing their screen`);
  } else if (data.type === "screen-share-stop") {
    remoteIsScreenSharing = false;
    updateScreenShareUI();
    // Only clear the banner if I'M not the one currently sharing — avoids
    // a race where their "stop" arrives right as I start, which would
    // otherwise wipe my own "You're sharing…" banner.
    if (!isScreenSharing) hideScreenShareBanner();
  } else if (["call-end", "call-busy", "call-decline"].includes(data.type)) {
    const reasonMap = { "call-busy": "busy", "call-decline": "declined" };
    teardownCall({ notifyRemote: false, reason: reasonMap[data.type] });
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
  currentFacingMode = "user";
  localStream = await navigator.mediaDevices.getUserMedia({
    audio: true,
    video: video ? { facingMode: "user" } : false,
  });
  if (video) {
    maybeShowFlipButton();
    setLocalMirrored(true); // front camera — mirror like a real mirror
  }
  return localStream;
}

// Shows the flip-camera button only when the device actually has more than
// one camera to switch between (most desktops/laptops have exactly one, so
// there's nothing to flip to).
async function maybeShowFlipButton() {
  const flipBtn = document.getElementById("video-flip-camera-btn");
  if (!flipBtn) return;

  try {
    const devices = await navigator.mediaDevices.enumerateDevices();
    const cameraCount = devices.filter((d) => d.kind === "videoinput").length;
    flipBtn.classList.toggle("hidden", cameraCount < 2);
  } catch (err) {
    flipBtn.classList.add("hidden");
  }
}

function hideFlipButton() {
  document.getElementById("video-flip-camera-btn")?.classList.add("hidden");
}

function hideScreenShareButton() {
  document.getElementById("video-screen-share-btn")?.classList.add("hidden");
}

function showScreenShareButtonIfVideoCall() {
  const btn = document.getElementById("video-screen-share-btn");
  if (!btn) return;
  btn.classList.toggle("hidden", callType !== "video");
}

function showScreenShareBanner(text) {
  const banner = document.getElementById("video-screen-share-banner");
  const textEl = document.getElementById("video-screen-share-banner-text");
  if (!banner) return;
  if (textEl) textEl.textContent = text;
  banner.classList.remove("hidden");
  banner.classList.add("flex");
}

function hideScreenShareBanner() {
  const banner = document.getElementById("video-screen-share-banner");
  if (!banner) return;
  banner.classList.add("hidden");
  banner.classList.remove("flex");
}


export async function flipCamera() {
  if (!localStream || callType !== "video" || isFlippingCamera || isScreenSharing) return;
  const oldTrack = localStream.getVideoTracks()[0];
  if (!oldTrack) return;

  const nextFacingMode = currentFacingMode === "user" ? "environment" : "user";
  isFlippingCamera = true;

  let newStream;
  try {
    newStream = await navigator.mediaDevices.getUserMedia({
      audio: false,
      video: { facingMode: { exact: nextFacingMode } },
    });
  } catch (err) {
    console.error("Camera flip failed:", err);
    isFlippingCamera = false;
    return;
  }

  const newTrack = newStream.getVideoTracks()[0];
  if (!newTrack) {
    isFlippingCamera = false;
    return;
  }

  if (peerConnection) {
    const sender = peerConnection.getSenders().find((s) => s.track && s.track.kind === "video");
    if (sender) {
      try {
        await sender.replaceTrack(newTrack);
      } catch (err) {
        console.error("replaceTrack failed during camera flip:", err);
        newTrack.stop();
        isFlippingCamera = false;
        return;
      }
    }
  }

  localStream.removeTrack(oldTrack);
  oldTrack.stop();
  localStream.addTrack(newTrack);
  newTrack.enabled = !isCameraOff;
  attachLocalPreview(localStream);

  currentFacingMode = nextFacingMode;
  setLocalMirrored(true); // front camera mirrors, back camera doesn't
  isFlippingCamera = false;
}

// ---- screen sharing ----
// Swaps the video track being SENT to the peer from the camera to a
// getDisplayMedia() capture, using the exact same replaceTrack() approach
// as flipCamera(). Only meaningful during an active video call.
//
// Mutual exclusion: enforced purely via the screen-share-start/-stop
// signals, not by inspecting media. remoteIsScreenSharing is the single
// source of truth for "is the other person currently sharing" on this
// browser; it's set by handleSignal() above, and toggleScreenShare()
// refuses to start a local share while it's true.
//
// Replacement, not hiding: once replaceTrack() swaps the sender's track,
// the OTHER participant's <video id="remote-video"> element keeps playing
// the same MediaStream it already has a reference to — WebRTC delivers the
// new frames on the existing track with no re-negotiation and no new
// "track" event. So the other person's view is never hidden or blanked;
// it just starts showing screen content instead of camera content,
// automatically. The banner below is purely an informational label on
// top of that, not something that gates the video itself.

export async function toggleScreenShare() {
  if (callType !== "video" || callState !== "connected") return;

  if (isScreenSharing) {
    await stopScreenShare();
    return;
  }

  if (remoteIsScreenSharing) {
    alert(`${getOtherParticipantName()} is already sharing their screen. You can share yours once they stop.`);
    return;
  }

  await startScreenShare();
}

async function startScreenShare() {
  if (!peerConnection || !localStream || isFlippingCamera) return;

  let displayStream;
  try {
    displayStream = await navigator.mediaDevices.getDisplayMedia({
      video: true,
      audio: false,
    });
  } catch (err) {
    // User cancelled the "choose a tab/window/screen" picker, or denied
    // permission — not worth alerting on, this is a normal outcome.
    console.log("Screen share cancelled or denied:", err);
    return;
  }

  const screenTrack = displayStream.getVideoTracks()[0];
  if (!screenTrack) return;

  const sender = peerConnection.getSenders().find((s) => s.track && s.track.kind === "video");
  if (sender) {
    try {
      await sender.replaceTrack(screenTrack);
    } catch (err) {
      console.error("replaceTrack failed when starting screen share:", err);
      screenTrack.stop();
      return;
    }
  }

  // Stash the live camera track (do NOT stop it) so it can be handed
  // straight back on stopScreenShare() without re-requesting the camera.
  cameraVideoTrack = localStream.getVideoTracks()[0] || null;
  screenStream = displayStream;
  isScreenSharing = true;

  // Local preview should show exactly what's being sent — the screen, not
  // your camera — so swap #local-video's srcObject to the capture too.
  attachLocalPreview(new MediaStream([screenTrack]));
  setLocalMirrored(false); // screen content is never mirrored

  sendSignal("screen-share-start", {});
  showScreenShareBanner("You're sharing your screen");

  // Every browser puts its own native "Stop sharing" bar/button on the
  // captured tab/window. If the user stops it from there instead of our
  // in-app button, the track ends on its own — listen for that so state
  // doesn't get stuck thinking we're still sharing.
  screenTrack.addEventListener("ended", () => {
    if (isScreenSharing) stopScreenShare();
  });

  updateScreenShareUI();
}

async function stopScreenShare() {
  if (!isScreenSharing) return;

  if (screenStream) {
    screenStream.getTracks().forEach((t) => t.stop());
    screenStream = null;
  }

  if (peerConnection && cameraVideoTrack) {
    const sender = peerConnection.getSenders().find((s) => s.track && s.track.kind === "video");
    if (sender) {
      try {
        await sender.replaceTrack(cameraVideoTrack);
      } catch (err) {
        console.error("replaceTrack failed when stopping screen share:", err);
      }
    }
  }

  isScreenSharing = false;
  cameraVideoTrack = null;

  if (localStream) {
    attachLocalPreview(localStream);
    setLocalMirrored(currentFacingMode === "user");
  }

  sendSignal("screen-share-stop", {});
  hideScreenShareBanner();
  updateScreenShareUI();
}

function updateScreenShareUI() {
  document.getElementById("video-screen-share-on-icon")?.classList.toggle("hidden", !isScreenSharing);
  document.getElementById("video-screen-share-off-icon")?.classList.toggle("hidden", isScreenSharing);

  const btn = document.getElementById("video-screen-share-btn");
  if (btn) {
    btn.classList.toggle("bg-green-600", isScreenSharing);
    btn.classList.toggle("hover:bg-green-700", isScreenSharing);
    btn.classList.toggle("bg-white/15", !isScreenSharing);
    btn.classList.toggle("hover:bg-white/25", !isScreenSharing);

    // Greyed out (but not literally disabled — clicking still shows the
    // "X is already sharing" alert rather than doing nothing silently)
    // whenever the OTHER person is sharing and I'm not.
    const blockedByRemote = remoteIsScreenSharing && !isScreenSharing;
    btn.classList.toggle("opacity-40", blockedByRemote);
  }
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
  resetVideoLayout(); // start each call remote-main / local-pip, default corner
  showScreenShareButtonIfVideoCall();
}

export function hideVideoCallUI() {
  const overlay = document.getElementById("video-call-overlay");
  if (!overlay) return;
  overlay.classList.add("hidden");
  overlay.classList.remove("flex");
  clearLocalPreview();
  clearRemoteVideo();
  resetVideoLayout(); // clean slate for next call
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
  const name = activeCallerName || "call";

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

async function logCallSummary(status) {
  const chatroomId = activeChatroomId || messagesContainer()?.dataset.chatroomId;
  const recipientId = activeRecipientId;
  if (!chatroomId || !recipientId) return;

  try {
    await fetch(`/chatrooms/${chatroomId}/calls`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken(),
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({
        recipient_id: recipientId,
        call_type: callType,
        status,
        duration_in_seconds: callSeconds,
      }),
    });
  } catch (err) {
    console.error("Call log error:", err);
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

export function teardownCall({ notifyRemote, signalType, reason } = {}) {
  const wasConnected = callState === "connected";
  const wasActive = callState === "calling" || callState === "ringing" || wasConnected;
  const status = wasConnected
    ? "answered"
    : reason === "declined"
      ? "declined"
      : reason === "busy"
        ? "busy"
        : "missed";

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
  if (screenStream) {
    screenStream.getTracks().forEach((t) => t.stop());
    screenStream = null;
  }
  document.getElementById("remote-audio")?.remove();

  if (notifyRemote) sendSignal(signalType || "call-end", {});
  // Only the browser that placed the call logs it — see isOutgoingCall.
  if (isOutgoingCall && wasActive) logCallSummary(status);

  isMuted = false;
  isCameraOff = false;
  currentFacingMode = "user";
  isFlippingCamera = false;
  isScreenSharing = false;
  cameraVideoTrack = null;
  remoteIsScreenSharing = false;
  resetMuteIcon();
  resetCameraIcon();
  updateScreenShareUI();
  hideScreenShareBanner();
  hideFlipButton();
  hideScreenShareButton();
  pendingOffer = null;
  callState = "idle";
  callType = "audio";
  isOutgoingCall = false;
  setActiveCall({ chatroomId: null, recipientId: null, callerName: null, callerAvatarUrl: null });
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
  document.getElementById("video-flip-camera-btn")?.addEventListener("click", flipCamera);
  document.getElementById("video-screen-share-btn")?.addEventListener("click", toggleScreenShare);

  initVideoLayout();
}