// app/javascript/chat/presence.js
import { createConsumer } from "@rails/actioncable";

let presenceConsumer = null;
let globalPresenceSub = null;
let otherMemberSub = null;

export function initGlobalPresence() {
  if (globalPresenceSub) return;

  presenceConsumer = presenceConsumer || createConsumer("/cable");
  globalPresenceSub = presenceConsumer.subscriptions.create({ channel: "PresenceChannel" }, {});
}

function formatLastSeen(isoString) {
  if (!isoString) return "Offline";

  const date = new Date(isoString);
  const now = new Date();
  const isToday = date.toDateString() === now.toDateString();

  const yesterday = new Date(now);
  yesterday.setDate(now.getDate() - 1);
  const isYesterday = date.toDateString() === yesterday.toDateString();

  const time = date.toLocaleTimeString([], { hour: "numeric", minute: "2-digit" });

  if (isToday) return `Last seen today at ${time}`;
  if (isYesterday) return `Last seen yesterday at ${time}`;

  const dateLabel = date.toLocaleDateString([], { month: "short", day: "numeric" });
  return `Last seen ${dateLabel} at ${time}`;
}

function setStatusUI(status, lastActiveAt) {
  const dot = document.getElementById("other-member-status-dot");
  const label = document.getElementById("other-member-status-label");
  if (!dot || !label) return;

  const isOnline = status === "online";
  dot.classList.toggle("bg-green-400", isOnline);
  dot.classList.toggle("bg-gray-400", !isOnline);
  label.textContent = isOnline ? "Active now" : formatLastSeen(lastActiveAt);
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
        setStatusUI(data.status, data.last_active_at);
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