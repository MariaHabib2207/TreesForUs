// app/javascript/chat/calling.js
// WebRTC voice calling over ActionCable's CallChannel: offer/answer/ICE
// signaling, ringtone, the in-call bar, and the incoming-call modal.
//
// NOTE (open investigation): if CallChannel's `subscribed` never appears to
// fire server-side, confirm the client is actually reaching the channel at
// all (check the Rails log for a CallChannel#subscribed line per page load)
// before assuming this client code is at fault — this has previously been
// traced back to broadcast stream name mismatches on the ChatroomChannel,
// so it's worth ruling the same category of bug out here too.

import { messagesContainer } from "./dom_utils";

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

function playRingtone() {
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

function stopRingtone() {
  if (ringOscInterval) {
    clearInterval(ringOscInterval);
    ringOscInterval = null;
  }
  if (ringAudioCtx) {
    ringAudioCtx.close().catch(() => {});
    ringAudioCtx = null;
  }
}

export function initCallChannel() {
  const container = messagesContainer();
  if (!container) return;
  const chatroomId = container.dataset.chatroomId;
  const currentUserId = container.dataset.currentUserId;

  if (!window.ActionCable) {
    setTimeout(initCallChannel, 100);
    return;
  }
  if (callSubscription) {
    callSubscription.unsubscribe();
    callSubscription = null;
  }

  const consumer = window.ActionCable.createConsumer("/cable");
  callSubscription = consumer.subscriptions.create(
    { channel: "CallChannel", chatroom_id: chatroomId },
    {
      received(data) {
        if (Number(data.sender_id) === Number(currentUserId)) return;
        console.log("Incoming call:", data);
        handleSignal(data);
      },
    }
  );
}

function sendSignal(type, payload) {
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
    showIncomingCallModal();
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

function createPeerConnection() {
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

  return pc;
}

function showCallBar(status, { showTimer, showMute } = {}) {
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

function hideCallBar() {
  const bar = document.getElementById("call-bar");
  bar.classList.add("hidden");
  bar.classList.remove("flex");
}

function showIncomingCallModal() {
  stopRingtone();
  playRingtone();
  const modal = document.getElementById("incoming-call-modal");
  const nameEl = document.getElementById("incoming-caller-name");
  nameEl.textContent = document.getElementById("other-member-name")?.textContent || "Someone";
  modal.classList.remove("hidden");
  modal.classList.add("flex");
  callState = "ringing";

  callTimeoutHandle = setTimeout(() => {
    teardownCall({ notifyRemote: true, signalType: "call-decline" });
  }, CALL_TIMEOUT_MS);
}

function hideIncomingCallModal() {
  const modal = document.getElementById("incoming-call-modal");
  modal.classList.add("hidden");
  modal.classList.remove("flex");
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

function onCallConnected() {
  clearTimeout(callTimeoutHandle);
  stopRingtone();
  callState = "connected";
  const name = document.getElementById("other-member-name")?.textContent || "call";
  showCallBar(`In call with ${name}`, { showTimer: true, showMute: true });
  startCallTimer();
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
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      body: JSON.stringify({ recipient_id: recipientId }),
    });
  } catch (err) {
    console.error("Missed call log error:", err);
  }
}

export function teardownCall({ notifyRemote, signalType } = {}) {
  const wasCalling = callState === "calling";
  const wasConnected = callState === "connected";

  clearTimeout(callTimeoutHandle);
  stopRingtone();
  stopCallTimer();
  hideIncomingCallModal();
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

function resetMuteIcon() {
  document.getElementById("mic-on-icon")?.classList.remove("hidden");
  document.getElementById("mic-off-icon")?.classList.add("hidden");
}

async function startCall() {
  if (callState !== "idle") return;

  try {
    localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
  } catch (err) {
    alert("Microphone access is required to make a call.");
    return;
  }

  peerConnection = createPeerConnection();
  localStream.getTracks().forEach((track) => peerConnection.addTrack(track, localStream));

  const offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);
  sendSignal("call-offer", offer);

  callState = "calling";
  const name = document.getElementById("other-member-name")?.textContent || "them";
  showCallBar(`Calling ${name}…`, { showTimer: false, showMute: false });
  playRingtone();

  callTimeoutHandle = setTimeout(() => {
    teardownCall({ notifyRemote: true, signalType: "call-end" });
  }, CALL_TIMEOUT_MS);
}

async function acceptCall() {
  if (!pendingOffer) return;
  clearTimeout(callTimeoutHandle);
  stopRingtone();
  hideIncomingCallModal();

  try {
    localStream = await navigator.mediaDevices.getUserMedia({ audio: true });
  } catch (err) {
    alert("Microphone access is required to answer the call.");
    teardownCall({ notifyRemote: true, signalType: "call-decline" });
    return;
  }

  peerConnection = createPeerConnection();
  localStream.getTracks().forEach((track) => peerConnection.addTrack(track, localStream));

  await peerConnection.setRemoteDescription(new RTCSessionDescription(pendingOffer));
  const answer = await peerConnection.createAnswer();
  await peerConnection.setLocalDescription(answer);
  sendSignal("call-answer", answer);

  onCallConnected();
}

function declineCall() {
  teardownCall({ notifyRemote: true, signalType: "call-decline" });
}

function toggleMute() {
  if (!localStream) return;
  isMuted = !isMuted;
  localStream.getAudioTracks().forEach((t) => {
    t.enabled = !isMuted;
  });
  document.getElementById("mic-on-icon")?.classList.toggle("hidden", isMuted);
  document.getElementById("mic-off-icon")?.classList.toggle("hidden", !isMuted);
}

export function initCalling() {
  document.getElementById("voice-call-btn")?.addEventListener("click", startCall);
  document.getElementById("accept-call-btn")?.addEventListener("click", acceptCall);
  document.getElementById("decline-call-btn")?.addEventListener("click", declineCall);
  document
    .getElementById("call-hangup-btn")
    ?.addEventListener("click", () => teardownCall({ notifyRemote: true, signalType: "call-end" }));
  document.getElementById("call-mute-btn")?.addEventListener("click", toggleMute);

  initCallChannel();
}

export function currentCallState() {
  return callState;
}
