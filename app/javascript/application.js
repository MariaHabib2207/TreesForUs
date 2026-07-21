// app/javascript/application.js

import "./chat/chatroom"; // chatroom-page-specific init (self-contained, see above)
import "./chat/tic_tac_toe";

import { initCallControls, teardownCall, currentCallState } from "./chat/call_session";
import { initIncomingCall } from "./chat/incoming_call";
import { initGlobalPresence } from "./chat/presence";

let globalCallInitialized = false;
let globalPresenceInitialized = false;

function initGlobalCallUI() {
  if (globalCallInitialized) return;
  if (!document.body.dataset.currentUserId) return; // signed out — nothing to ring

  initIncomingCall(); // the one and only CallChannel subscription
  initCallControls(); // hangup/mute buttons on the call-bar & video overlay
  globalCallInitialized = true;
}

function initGlobalPresenceUI() {
  if (globalPresenceInitialized) return;
  if (!document.body.dataset.currentUserId) return; // signed out — nothing to broadcast

  initGlobalPresence(); // the one and only PresenceChannel subscription
  globalPresenceInitialized = true;
}

document.addEventListener("turbo:load", () => {
  initIncomingCall();
  initCallControls();
  initGlobalPresenceUI();
});
document.addEventListener("DOMContentLoaded", () => {
  initGlobalCallUI();
  initGlobalPresenceUI();
});

import { initAllGameroomPanels, initGameChannel } from "./chat/gameroom";

document.addEventListener("turbo:load", initAllGameroomPanels);
document.addEventListener("DOMContentLoaded", initAllGameroomPanels);
document.addEventListener("turbo:load", initGameChannel);
document.addEventListener("DOMContentLoaded", initGameChannel);