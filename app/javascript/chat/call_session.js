// app/javascript/chat/call_session.js
// Shared plumbing for voice calls: the CallChannel subscription, WebRTC
// peer connection setup, the in-call bar, ringtone, and teardown.
//
// This module owns all the state that both the outgoing call button
// (outgoing_call.js) and the incoming call modal (incoming_call.js) need to
// read or mutate, so neither of those files touches ActionCable or
// RTCPeerConnection directly — they just call the functions here.
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
let callTimerInterval = null;
let callSeconds = 0;
let callTimeoutHandle = null;
let pendingOffer = null;
let isMuted = false;
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

async function handleSignal(data) {
  if (data.type === "call-offer") {
    if (callState !== "idle") {
      sendSignal("call-busy", {});
      return;
    }
    pendingOffer = data.payload;
    callState = "ringing";
    if (offerHandler) offerHandler(data.payload);
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
    let remoteAudio = document.getElementById("remote-audio");
    if (!remoteAudio) {
      remoteAudio = document.createElement("audio");
      remoteAudio.id = "remote-audio";
      remoteAudio.autoplay = true;
      document.body.appendChild(remoteAudio);
    }
    remoteAudio.srcObject = e.streams[0];
  };

  pc.onconnectionstatechange = () => {
    if (["disconnected", "failed", "closed"].includes(pc.connectionState) && callState !== "idle") {
      teardownCall({ notifyRemote: false });
    }
  };

  peerConnection = pc;
  return pc;
}

export async function acquireMicrophone() {
  localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
  return localStream;
}

export function attachLocalTracks(pc, stream) {
  stream.getTracks().forEach((track) => pc.addTrack(track, stream));
}

// ---- call bar / timer ----

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

function startCallTimer() {
  callSeconds = 0;
  const timerEl = document.getElementById("call-timer");
  timerEl.textContent = "00:00";
  callTimerInterval = setInterval(() => {
    callSeconds++;
    const m = String(Math.floor(callSeconds / 60)).padStart(2, "0");
    const s = String(callSeconds % 60).padStart(2, "0");
    timerEl.textContent = `${m}:${s}`;
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
  showCallBar(`In call with ${name}`, { showTimer: true, showMute: true });
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
  const recipientId = document.getElementById("voice-call-btn")?.dataset.recipientId;
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
}

export function toggleMute() {
  if (!localStream) return;
  isMuted = !isMuted;
  localStream.getAudioTracks().forEach((t) => {
    t.enabled = !isMuted;
  });
  document.getElementById("mic-on-icon")?.classList.toggle("hidden", isMuted);
  document.getElementById("mic-off-icon")?.classList.toggle("hidden", !isMuted);
}

export function teardownCall({ notifyRemote, signalType } = {}) {
  const wasCalling = callState === "calling";
  const wasConnected = callState === "connected";

  clearTimeout(callTimeoutHandle);
  stopRingtone();
  stopCallTimer();
  hideCallBar();

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
  resetMuteIcon();
  pendingOffer = null;
  callState = "idle";
}

export function initCallControls() {
  document
    .getElementById("call-hangup-btn")
    ?.addEventListener("click", () => teardownCall({ notifyRemote: true, signalType: "call-end" }));
  document.getElementById("call-mute-btn")?.addEventListener("click", toggleMute);
}