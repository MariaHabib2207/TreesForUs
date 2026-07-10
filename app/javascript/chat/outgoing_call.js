// app/javascript/chat/outgoing_call.js
// Owns exactly one thing: the "Call" button that places an outgoing call.
// Everything about receiving/answering a call lives in incoming_call.js —
// this file never touches the incoming-call modal.

import {
  currentCallState,
  setCallState,
  createPeerConnection,
  acquireMicrophone,
  attachLocalTracks,
  sendSignal,
  showCallBar,
  playRingtone,
  scheduleCallTimeout,
  teardownCall,
} from "./call_session";

async function startCall() {
  if (currentCallState() !== "idle") return;

  let localStream;
  try {
    localStream = await acquireMicrophone();
  } catch (err) {
    alert("Microphone access is required to make a call.");
    return;
  }

  const peerConnection = createPeerConnection();
  attachLocalTracks(peerConnection, localStream);

  const offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);
  sendSignal("call-offer", offer);

  setCallState("calling");
  const name = document.getElementById("other-member-name")?.textContent || "them";
  showCallBar(`Calling ${name}…`, { showTimer: false, showMute: false });
  playRingtone();

  scheduleCallTimeout(() => {
    teardownCall({ notifyRemote: true, signalType: "call-end" });
  });
}

export function initOutgoingCall() {
  document.getElementById("voice-call-btn")?.addEventListener("click", startCall);
}