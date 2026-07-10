// app/javascript/chat/dom_utils.js
// Small, dependency-free DOM helpers shared by the messaging, calling,
// and voice-note modules. Kept framework-agnostic so it's easy to test.

export function messagesContainer() {
  return document.getElementById("messages-container");
}

export function scrollToBottom() {
  const c = messagesContainer();
  if (c) c.scrollTop = c.scrollHeight;
}

export function isNearBottom(container, threshold = 120) {
  return container.scrollHeight - container.scrollTop - container.clientHeight < threshold;
}

export function markMineIfNeeded(row, senderId, currentUserId) {
  if (Number(senderId) === Number(currentUserId)) {
    row.classList.add("message-row--mine");
    const bubble = row.querySelector(".message-bubble");
    if (bubble) bubble.classList.add("message-bubble--mine");
  }
}

// Appends a server-rendered message row (HTML string) to the container,
// de-duplicating by data-message-id and preserving scroll position unless
// the user is already near the bottom (or forceStick is passed, e.g. for
// messages the current user just sent).
export function appendMessageRow(html, currentUserId, { forceStick } = {}) {
  const container = messagesContainer();
  if (!container) return;

  const temp = document.createElement("div");
  temp.innerHTML = html.trim();
  const row = temp.firstElementChild;
  if (!row) return;

  const id = row.dataset.messageId;
  if (id && container.querySelector(`[data-message-id="${id}"]`)) return;

  const shouldStick = forceStick || isNearBottom(container);
  container.appendChild(row);
  markMineIfNeeded(row, row.dataset.senderId, currentUserId);
  if (shouldStick) scrollToBottom();
}

export function getLastMessageId(container) {
  const rows = container.querySelectorAll("[data-message-id]");
  if (rows.length === 0) return null;
  return rows[rows.length - 1].dataset.messageId;
}

export function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]').content;
}

export function formatMinutesSeconds(totalSeconds) {
  const m = Math.floor(totalSeconds / 60);
  const s = String(totalSeconds % 60).padStart(2, "0");
  return `${m}:${s}`;
}

export function formatDuration(seconds) {
  const s = Math.max(0, Math.floor(seconds || 0));
  return formatMinutesSeconds(s);
}
