// app/javascript/chat/incoming_call.js
// Owns the incoming-call popup: showing it when an offer arrives (audio or
// video), and wiring Accept/Decline. This is the only file that touches
// #incoming-call-modal.
console.log("incoming_call.js loaded, subscribing to CallChannel");
import {
  getPendingOffer,
  setPendingOffer,
  setCallType,
  createPeerConnection,
  acquireMediaStream,
  attachLocalTracks,
  attachLocalPreview,
  sendSignal,
  onCallConnected,
  playRingtone,
  stopRingtone,
  scheduleCallTimeout,
  clearCallTimeout,
  teardownCall,
  initCallChannel,
} from "./call_session";

function showIncomingCallModal(offerPayload) {
  setPendingOffer(offerPayload);
  setCallType(offerPayload?.video ? "video" : "audio");

  stopRingtone();
  playRingtone();

  const modal = document.getElementById("incoming-call-modal");
  const nameEl = document.getElementById("incoming-caller-name");
  const typeLabel = document.getElementById("incoming-call-type-label");
  nameEl.textContent = document.getElementById("other-member-name")?.textContent || "Someone";
  if (typeLabel) {
    typeLabel.textContent = offerPayload?.video ? "Incoming video call…" : "Incoming voice call…";
  }
  modal.classList.remove("hidden");
  modal.classList.add("flex");

  scheduleCallTimeout(() => {
    teardownCall({ notifyRemote: true, signalType: "call-decline" });
  });
}

function hideIncomingCallModal() {
  const modal = document.getElementById("incoming-call-modal");
  modal.classList.add("hidden");
  modal.classList.remove("flex");
}

async function acceptCall() {
  const pendingOffer = getPendingOffer();
  if (!pendingOffer) return;

  const isVideo = !!pendingOffer.video;

  if (!pendingOffer.sdp || typeof pendingOffer.sdp.type !== "string") {
    console.error("[CallChannel] Refusing to accept — offer has no usable SDP:", pendingOffer);
    alert("That call couldn't be connected (bad signal). Please ask them to call again.");
    hideIncomingCallModal();
    teardownCall({ notifyRemote: true, signalType: "call-decline" });
    return;
  }

  clearCallTimeout();
  stopRingtone();
  hideIncomingCallModal();

  let localStream;
  try {
    localStream = await acquireMediaStream(isVideo);
  } catch (err) {
    alert(
      isVideo
        ? "Camera and microphone access is required to answer the call."
        : "Microphone access is required to answer the call."
    );
    teardownCall({ notifyRemote: true, signalType: "call-decline" });
    return;
  }

  const peerConnection = createPeerConnection();
  attachLocalTracks(peerConnection, localStream);

  if (isVideo) attachLocalPreview(localStream);

  await peerConnection.setRemoteDescription(new RTCSessionDescription(pendingOffer.sdp));
  const answer = await peerConnection.createAnswer();
  await peerConnection.setLocalDescription(answer);
  sendSignal("call-answer", answer);

  onCallConnected();
}

function declineCall() {
  hideIncomingCallModal();
  teardownCall({ notifyRemote: true, signalType: "call-decline" });
}

export function initIncomingCall() {
  document.getElementById("accept-call-btn")?.addEventListener("click", acceptCall);
  document.getElementById("decline-call-btn")?.addEventListener("click", declineCall);

  // This is the one place that subscribes to CallChannel — outgoing_call.js
  // just sends signals through call_session.js once this is live.
  initCallChannel({
    onOffer(offerPayload) {
      showIncomingCallModal(offerPayload);
    },
  });
}

// Exposed for chatroom.js teardown so the modal is hidden if the page
// unloads mid-ring.
export function hideIncomingCallModalIfShown() {
  hideIncomingCallModal();
}
