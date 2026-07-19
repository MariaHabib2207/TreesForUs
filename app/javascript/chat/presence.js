

import { createConsumer } from "@rails/actioncable";

let presenceConsumer = null;
let globalPresenceSub = null;
let otherMemberSub = null;

export function initGlobalPresence() {
  if (globalPresenceSub) return; // already registered for this session

  presenceConsumer = presenceConsumer || createConsumer("/cable");
  globalPresenceSub = presenceConsumer.subscriptions.create({ channel: "PresenceChannel" }, {});
}

function setStatusUI(status) {
  const dot = document.getElementById("other-member-status-dot");
  const label = document.getElementById("other-member-status-label");
  if (!dot || !label) return;

  const isOnline = status === "online";
  dot.classList.toggle("bg-green-400", isOnline);
  dot.classList.toggle("bg-gray-400", !isOnline);
  label.textContent = isOnline ? "Active now" : "Offline";
}

export function initOtherMemberPresence() {
  const container = document.getElementById("messages-container");
  const otherUserId = container?.dataset.otherUserId;
  if (!otherUserId) return;

  teardownOtherMemberPresence();

  const consumer = presenceConsumer || createConsumer("/cable");
  presenceConsumer = consumer;

  otherMemberSub = consumer.subscriptions.create(
    { channel: "UserStatusChannel", user_id: otherUserId },
    {
      received(data) {
        setStatusUI(data.status);
      },
    }
  );
}

export function teardownOtherMemberPresence() {
  if (otherMemberSub) {
    otherMemberSub.unsubscribe();
    otherMemberSub = null;
  }
}