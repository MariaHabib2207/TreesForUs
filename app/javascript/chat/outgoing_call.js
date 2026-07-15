// app/javascript/chat/outgoing_call.js
// Owns the two outbound-call buttons: "Call" (audio) and "Video call".
// Everything about receiving/answering a call lives in incoming_call.js —
// this file never touches the incoming-call modal.

import {
  currentCallState,
  setCallState,
  setCallType,
  setOutgoingCall,
  setActiveCall,
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
import { messagesContainer } from "./dom_utils";

async function startCall(video, buttonEl) {
  if (currentCallState() !== "idle") return;

  // MUST happen before any WebRTC setup — createPeerConnection() wires up
  // onicecandidate, which starts firing sendSignal("ice-candidate", ...)
  // as soon as setLocalDescription() runs below. Without recipientId set
  // first, every one of those candidates (and the offer itself) is
  // silently dropped by sendSignal()'s guard clause.
  const chatroomId = messagesContainer()?.dataset.chatroomId;
  const recipientId = buttonEl?.dataset.recipientId;

  if (!recipientId) {
    console.error("[outgoing_call] No recipientId found on call button — check data-recipient-id in the view.");
    alert("Can't start the call — missing recipient info. Please refresh and try again.");
    return;
  }

  setActiveCall({ chatroomId, recipientId });

  let localStream;
  try {
    localStream = await acquireMediaStream(video);
  } catch (err) {
    alert(
      video
        ? "Camera and microphone access is required to make a video call."
        : "Microphone access is required to make a call."
    );
    setActiveCall({ chatroomId: null, recipientId: null });
    return;
  }

  setCallType(video ? "video" : "audio");
  setOutgoingCall(true);

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
  document.getElementById("voice-call-btn")?.addEventListener("click", (e) => startCall(false, e.currentTarget));
  document.getElementById("video-call-btn")?.addEventListener("click", (e) => startCall(true, e.currentTarget));
}