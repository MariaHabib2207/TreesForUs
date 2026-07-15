// app/javascript/chat/incoming_call.js
// Owns the incoming-call popup: showing it when an offer arrives (audio or
// video), and wiring Accept/Decline. This is the only file that touches
// #incoming-call-modal. Works from any page — the modal lives in a
// data-turbo-permanent partial, and caller name/avatar come from the
// signal payload rather than any chatroom-page DOM element.
console.log("incoming_call.js loaded, subscribing to CallChannel");
import {
  getPendingOffer,
  getActiveCall,
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
import { messagesContainer } from "./dom_utils";

function showIncomingCallModal(offerPayload) {
  const { callerName, callerAvatarUrl } = getActiveCall();

  stopRingtone();
  playRingtone();

  const modal = document.getElementById("incoming-call-modal");
  const nameEl = document.getElementById("incoming-caller-name");
  const typeLabel = document.getElementById("incoming-call-type-label");
  const avatarImg = document.getElementById("incoming-caller-avatar-img");
  const avatarFallback = document.getElementById("incoming-caller-avatar-fallback");

  nameEl.textContent = callerName || "Someone";
  if (typeLabel) {
    typeLabel.textContent = offerPayload?.video ? "Incoming video call…" : "Incoming voice call…";
  }

  if (callerAvatarUrl) {
    avatarImg.src = callerAvatarUrl;
    avatarImg.classList.remove("hidden");
    avatarFallback.classList.add("hidden");
  } else {
    avatarImg.classList.add("hidden");
    avatarFallback.classList.remove("hidden");
    avatarFallback.textContent = (callerName || "?").slice(0, 2).toUpperCase();
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
  const { chatroomId } = getActiveCall();

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

  // If the call came in while the user was somewhere other than that
  // chatroom, take them there now. The call UI itself (bar/overlay) is
  // data-turbo-permanent, so this navigation doesn't interrupt the call.
  const currentChatroomId = messagesContainer()?.dataset.chatroomId;
  if (chatroomId && String(currentChatroomId) !== String(chatroomId) && window.Turbo) {
    window.Turbo.visit(`/chatrooms/${chatroomId}`);
  }
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

// Exposed in case any page-specific teardown needs to hide the modal
// explicitly (e.g. mid-ring cleanup).
export function hideIncomingCallModalIfShown() {
  hideIncomingCallModal();
}