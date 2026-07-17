// app/javascript/chat/message_deletion.js
import { messagesContainer } from "./dom_utils";

function buildPopover(isMine) {
  const el = document.createElement("div");
  el.className = "message-delete-popover absolute z-30 bg-white rounded-xl shadow-lg py-1 text-sm w-40";
  el.innerHTML = `
    <button type="button" data-action="me" class="w-full text-left px-3 py-2 hover:bg-black/5">Delete for me</button>
    ${isMine ? `<button type="button" data-action="everyone" class="w-full text-left px-3 py-2 hover:bg-black/5 text-red-600">Delete for everyone</button>` : ""}
  `;
  return el;
}

function closeOpenPopover() {
  document.querySelectorAll(".message-delete-popover").forEach((p) => p.remove());
}

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content;
}

// "Delete for me" — only affects this browser/user. Removes the row
// locally; no broadcast involved, nothing for other users to receive.
async function deleteForMe(messageId) {
  if (!messageId) return;

  const res = await fetch(`/messages/${messageId}?scope=me`, {
    method: "DELETE",
    headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
  });
  if (!res.ok) return;

  const row = messagesContainer()?.querySelector(`[data-message-id="${messageId}"]`);
  row?.remove();
}

// "Delete for everyone" — the sender's own screen updates immediately here;
// every other participant's screen updates via the ActionCable broadcast
// handled in applyDeletionBroadcast (see cable_messages.js), not this
// function directly.
async function deleteForEveryone(messageId) {
  if (!messageId) return;

  const res = await fetch(`/messages/${messageId}?scope=everyone`, {
    method: "DELETE",
    headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
  });
  if (!res.ok) return;

  applyDeletionBroadcast(messageId);
}

async function deleteCall(callMessageId, callId) {
  if (!callId) return;

  const res = await fetch(`/calls/${callId}`, {
    method: "DELETE",
    headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
  });
  if (!res.ok) return;

  const row = messagesContainer()?.querySelector(`[data-message-id="${callMessageId}"]`);
  row?.remove();
}

export function initMessageDeletion() {
  const container = messagesContainer();
  if (!container) return;

  container.addEventListener("click", (e) => {
    const callTrigger = e.target.closest(".call-delete-trigger");
    const trigger = e.target.closest(".message-delete-trigger");
    const popoverAction = e.target.closest(".message-delete-popover button");

    if (callTrigger) {
      e.stopPropagation();
      deleteCall(callTrigger.dataset.callMessageId, callTrigger.dataset.callId);
      return;
    }

    if (trigger) {
      e.stopPropagation();
      closeOpenPopover();

      const isMine = trigger.dataset.isMine === "true";
      const messageId = trigger.dataset.messageId;

      const popover = buildPopover(isMine);
      popover.dataset.messageId = messageId;
      popover.style.top = "28px";
      popover.style.left = "0px";

      trigger.parentElement.appendChild(popover);
      return;
    }

    if (popoverAction) {
      e.stopPropagation();
      const popoverEl = popoverAction.closest(".message-delete-popover");
      const messageId = popoverEl?.dataset.messageId;

      if (popoverAction.dataset.action === "everyone") {
        deleteForEveryone(messageId);
      } else {
        deleteForMe(messageId);
      }

      closeOpenPopover();
      return;
    }

    closeOpenPopover();
  });
}

// Called both locally (right after a successful "delete for everyone"
// request, for the sender's own screen) and from cable_messages.js when
// the broadcast arrives on other participants' screens.
export function applyDeletionBroadcast(messageId) {
  const row = messagesContainer()?.querySelector(`[data-message-id="${messageId}"]`);
  if (!row) return;

  const bubble = row.querySelector(".message-bubble");
  if (!bubble) return;

  bubble.className = bubble.className.replace("message-bubble--mine", "").trim() + " bg-white/60";
  bubble.innerHTML = `<p class="text-xs italic text-gray-400">This message was deleted</p>`;
}