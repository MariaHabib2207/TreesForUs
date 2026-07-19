

import { messagesContainer } from "./dom_utils";

const SINGLE_CHECK = 'M5 13l4 4L19 7';
const DOUBLE_CHECK = 'M5 13l3 3 3-3m2 3l7-9M9 16l7-9';

function renderTick(tickEl, { delivered, read }) {
  const colorClass = read ? "text-green-500" : "text-gray-400";
  const path = delivered || read ? DOUBLE_CHECK : SINGLE_CHECK;

  tickEl.dataset.delivered = String(delivered);
  tickEl.dataset.read = String(read);
  tickEl.innerHTML = `
    <svg class="w-3.5 h-3.5 ${colorClass}" fill="none" stroke="currentColor" viewBox="0 0 24 24">
      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="${path}"></path>
    </svg>
  `;
}

export function applyDeliveredBroadcast(messageIds) {
  const container = messagesContainer();
  if (!container) return;

  messageIds.forEach((id) => {
    const tick = container.querySelector(`.message-status-tick[data-message-id="${id}"]`);
    if (!tick) return;
    if (tick.dataset.read === "true") return; // read already implies delivered visually
    renderTick(tick, { delivered: true, read: false });
  });
}

export function applyReadBroadcast(messageIds) {
  const container = messagesContainer();
  if (!container) return;

  messageIds.forEach((id) => {
    const tick = container.querySelector(`.message-status-tick[data-message-id="${id}"]`);
    if (!tick) return;
    renderTick(tick, { delivered: true, read: true });
  });
}