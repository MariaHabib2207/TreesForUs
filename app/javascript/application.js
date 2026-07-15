

import "./chat/chatroom"; // chatroom-page-specific init (self-contained, see above)


import { initCallControls, teardownCall, currentCallState } from "./chat/call_session";
import { initIncomingCall } from "./chat/incoming_call";

let globalCallInitialized = false;

function initGlobalCallUI() {
  if (globalCallInitialized) return;
  if (!document.body.dataset.currentUserId) return; // signed out — nothing to ring

  initIncomingCall(); // the one and only CallChannel subscription
  initCallControls(); // hangup/mute buttons on the call-bar & video overlay
  globalCallInitialized = true;
}

document.addEventListener("turbo:load", () => {
  initIncomingCall();
  initCallControls();
});
document.addEventListener("DOMContentLoaded", initGlobalCallUI);
