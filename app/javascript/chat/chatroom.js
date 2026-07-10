// app/javascript/chat/chatroom.js
// Entry point for the chatroom show page. Wires up all the chat modules and
// owns the Turbo lifecycle guard that used to live inline in the view.
//
// Import this from app/javascript/application.js, e.g.:
//   import "chat/chatroom"

import { scrollToBottom, messagesContainer } from "./dom_utils";
import { initActionCable, teardownActionCable, startPolling, stopPolling } from "./cable_messages";
import { initMessageForm, stopRecordingIfActive } from "./message_form";
import { initVoicePlayers, stopActiveVoiceAudio } from "./voice_player";
import { initAddPeople } from "./add_people";
import { initCalling, teardownCall, currentCallState } from "./calling";

function init() {
  if (!messagesContainer()) return;
  scrollToBottom();
  initActionCable();
  initMessageForm();
  initVoicePlayers();
  initAddPeople();
  initCalling();
  startPolling();
}

function teardown() {
  teardownActionCable();
  stopPolling();
  stopRecordingIfActive();
  stopActiveVoiceAudio();
  if (currentCallState() !== "idle") {
    teardownCall({ notifyRemote: true, signalType: "call-end" });
  }
}

// Guard against DOMContentLoaded and turbo:load both firing for the same
// page load, which used to double-bind the submit handler, double-subscribe
// to ActionCable channels, and could cause a single tap of "Send" to POST
// the same message twice.
//
// IMPORTANT: pageInitialized is only ever reset to false in
// turbo:before-cache (i.e. when navigating away). It must NOT be reset
// inside the turbo:load handler itself — doing that defeats the guard and
// causes init() to run twice on every page load, doubling the ActionCable
// subscription and the polling interval.
let pageInitialized = false;
function safeInit() {
  if (pageInitialized) return;
  pageInitialized = true;
  init();
}

document.addEventListener("turbo:load", safeInit);
document.addEventListener("DOMContentLoaded", safeInit);

document.addEventListener("turbo:before-cache", () => {
  pageInitialized = false;
  teardown();
});
