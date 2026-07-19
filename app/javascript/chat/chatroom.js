// app/javascript/chat/chatroom.js
// Chatroom-page-specific setup: messages (ActionCable + polling fallback),
// the message composer, voice message playback, the "add people" modal,
// message/call deletion, and the outbound call buttons (Call / Video call) —
// all of which only exist when #messages-container is on the page.
//
// Global call plumbing (the CallChannel subscription, the incoming-call
// modal, and the audio/video call controls) does NOT live here anymore —
// it's initialized once, globally, in application.js, because it has to
// keep working on every page the user navigates to, not just this one.
// See application.js for that.

import { scrollToBottom, messagesContainer } from "./dom_utils";
import { initActionCable, teardownActionCable, startPolling, stopPolling } from "./cable_messages";
import { initMessageForm, stopRecordingIfActive } from "./message_form";
import { initVoicePlayers, stopActiveVoiceAudio } from "./voice_player";
import { initAddPeople } from "./add_people";
import { initOutgoingCall } from "./outgoing_call";
import { initMessageDeletion } from "./message_deletion";
import { initOtherMemberPresence, teardownOtherMemberPresence } from "./presence";
import { initPrivacyToggles } from "./privacy";

function init() {
  if (!messagesContainer()) return;
  scrollToBottom();
  initActionCable();
  initMessageForm();
  initVoicePlayers();
  initAddPeople();
  initOutgoingCall();
  initMessageDeletion();
  initOtherMemberPresence();
  startPolling();
  initPrivacyToggles();
}

function teardown() {
  teardownActionCable();
  stopPolling();
  stopRecordingIfActive();
  stopActiveVoiceAudio();
  teardownOtherMemberPresence();
  // NOTE: no call teardown here anymore. An active/ringing call must
  // survive navigating away from the chatroom page — the call UI is
  // data-turbo-permanent and the CallChannel subscription is global, so
  // leaving this page should not hang up or decline a call in progress.
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