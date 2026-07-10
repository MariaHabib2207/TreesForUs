// app/javascript/chat/cable_messages.js
// Handles real-time message delivery over ActionCable's ChatroomChannel,
// with an HTTP-polling fallback so messages still arrive if the socket
// never connects.
//
// NOTE (open investigation): if `connected()` below never logs, check for
// stream-name mismatches between raw strings (e.g. "chatroom_#{id}") used
// server-side in controllers/jobs vs. the GlobalID-based stream that
// `stream_for` generates in the channel. A silent mismatch here is exactly
// what makes polling mask a broken cable subscription.

import {
  appendMessageRow,
  getLastMessageId,
  messagesContainer,
  isNearBottom,
  scrollToBottom,
  markMineIfNeeded,
} from "./dom_utils";

const POLL_MS = 3000;

let subscription = null;
let pollInterval = null;
let cableConfirmedConnected = false;

export function isCableConfirmedConnected() {
  return cableConfirmedConnected;
}

export function initActionCable() {
  const container = messagesContainer();
  if (!container) return;

  const chatroomId = container.dataset.chatroomId;
  const currentUserId = container.dataset.currentUserId;

  if (!window.ActionCable) {
    setTimeout(initActionCable, 100);
    return;
  }

  teardownActionCable();

  const consumer = window.ActionCable.createConsumer("/cable");
  subscription = consumer.subscriptions.create(
    { channel: "ChatroomChannel", chatroom_id: chatroomId },
    {
      connected() {
        console.log("[ActionCable] Connected to ChatroomChannel", chatroomId);
        cableConfirmedConnected = true;
      },
      disconnected() {
        console.log("[ActionCable] Disconnected");
        cableConfirmedConnected = false;
      },
      received(data) {
        if (Number(data.sender_id) === Number(currentUserId)) return;
        appendMessageRow(data.message_html, currentUserId);
      },
    }
  );
}

export function teardownActionCable() {
  if (subscription) {
    subscription.unsubscribe();
    subscription = null;
  }
  cableConfirmedConnected = false;
}

export function startPolling() {
  const container = messagesContainer();
  if (!container) return;

  stopPolling();

  pollInterval = setInterval(async () => {
    const chatroomId = container.dataset.chatroomId;
    const currentUserId = container.dataset.currentUserId;
    const lastId = getLastMessageId(container);

    try {
      const response = await fetch(
        `/chatrooms/${chatroomId}/messages/poll?after=${lastId || ""}`,
        { headers: { Accept: "application/json" } }
      );
      if (!response.ok) return;

      const data = await response.json();
      if (!data.messages_html) return;

      const temp = document.createElement("div");
      temp.innerHTML = data.messages_html;
      const newRows = Array.from(temp.children);
      if (newRows.length === 0) return;

      const shouldStick = isNearBottom(container);
      newRows.forEach((row) => {
        const id = row.dataset.messageId;
        if (id && container.querySelector(`[data-message-id="${id}"]`)) return;
        container.appendChild(row);
        markMineIfNeeded(row, row.dataset.senderId, currentUserId);
      });
      if (shouldStick) scrollToBottom();
    } catch (err) {
      console.error("Poll error:", err);
    }
  }, POLL_MS);
}

export function stopPolling() {
  if (pollInterval) {
    clearInterval(pollInterval);
    pollInterval = null;
  }
}
