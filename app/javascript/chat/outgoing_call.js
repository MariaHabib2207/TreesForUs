// app/javascript/chat/outgoing_call.js
// Owns the two outbound-call buttons: "Call" (audio) and "Video call".
// Everything about receiving/answering a call lives in incoming_call.js —
// this file never touches the incoming-call modal.

import {
  currentCallState,
  setCallState,
  setCallType,
  createPeerConnection,
  acquireMediaStream,
  attachLocalTracks,
  attachLocalPreview,
  sendSignal,
  showCallBar,
  showVideoCallUI,
  playRingtone,
  scheduleCallTimeout,
  teardownCall,
} from "./call_session";

async function startCall(video) {
  if (currentCallState() !== "idle") return;

  let localStream;
  try {
    localStream = await acquireMediaStream(video);
  } catch (err) {
    alert(
      video
        ? "Camera and microphone access is required to make a video call."
        : "Microphone access is required to make a call."
    );
    return;
  }

  setCallType(video ? "video" : "audio");

  const peerConnection = createPeerConnection();
  attachLocalTracks(peerConnection, localStream);

  const offer = await peerConnection.createOffer();
  await peerConnection.setLocalDescription(offer);
  sendSignal("call-offer", { sdp: offer, video });

  setCallState("calling");
  const name = document.getElementById("other-member-name")?.textContent || "them";

  if (video) {
    attachLocalPreview(localStream);
    showVideoCallUI(`Calling ${name}…`, { showTimer: false });
  } else {
    showCallBar(`Calling ${name}…`, { showTimer: false, showMute: false });
  }
  playRingtone();

  scheduleCallTimeout(() => {
    teardownCall({ notifyRemote: true, signalType: "call-end" });
  });
}

export function initOutgoingCall() {
  document.getElementById("voice-call-btn")?.addEventListener("click", () => startCall(false));
  document.getElementById("video-call-btn")?.addEventListener("click", () => startCall(true));
}
