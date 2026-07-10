
import { scrollToBottom, messagesContainer } from "./dom_utils";
import { initActionCable, teardownActionCable, startPolling, stopPolling } from "./cable_messages";
import { initMessageForm, stopRecordingIfActive } from "./message_form";
import { initVoicePlayers, stopActiveVoiceAudio } from "./voice_player";
import { initAddPeople } from "./add_people";
import { initCallControls, teardownCall, currentCallState } from "./call_session";
import { initOutgoingCall } from "./outgoing_call";
import { initIncomingCall } from "./incoming_call";

function init() {
  if (!messagesContainer()) return;
  scrollToBottom();
  initActionCable();
  initMessageForm();
  initVoicePlayers();
  initAddPeople();
  initCallControls();
  initOutgoingCall();
  initIncomingCall();
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