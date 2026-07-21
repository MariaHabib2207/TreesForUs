// app/javascript/chat/gameroom.js
// Gameroom panel: search-to-invite UI (mirrors _notification_bell.html.slim's
// open/close pattern via inline style.display, not Tailwind class toggling),
// plus the global GameChannel subscription for game_started / game_declined
// signals. Initialized once per full page load; safe to call multiple times.

import { csrfToken } from "./dom_utils";
import { createConsumer } from "@rails/actioncable";

let gameConsumer = null;
let gameSubscription = null;

function initGameroomPanel(suffix) {
  const btn = document.getElementById("gameroom-btn-" + suffix);
  const panel = document.getElementById("gameroom-panel-" + suffix);
  const backdrop = document.getElementById("gameroom-backdrop-" + suffix);
  const closeBtn = document.getElementById("gameroom-close-btn-" + suffix);
  const input = document.getElementById("gameroom-search-input-" + suffix);
  const results = document.getElementById("gameroom-search-results-" + suffix);

  if (!btn || !panel) return;
  if (btn.dataset.gameroomInit === "true") return;
  btn.dataset.gameroomInit = "true";

  function openPanel() {
    panel.style.display = "flex";
    if (backdrop) backdrop.style.display = "block";
  }

  function closePanel() {
    panel.style.display = "none";
    if (backdrop) backdrop.style.display = "none";
  }

  function isOpen() {
    return panel.style.display !== "none" && panel.style.display !== "";
  }

  btn.addEventListener("click", (e) => {
    e.stopPropagation();
    isOpen() ? closePanel() : openPanel();
  });

  closeBtn?.addEventListener("click", closePanel);
  backdrop?.addEventListener("click", closePanel);

  document.addEventListener("click", (e) => {
    if (!panel.contains(e.target) && !btn.contains(e.target)) closePanel();
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape") closePanel();
  });

  panel.__closeGameroom = closePanel;

  initGameroomSearch(input, results);
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.textContent = str || "";
  return div.innerHTML;
}

function initGameroomSearch(input, results) {
  if (!input || !results) return;
  if (input.dataset.searchInit === "true") return;
  input.dataset.searchInit = "true";

  let debounceTimer = null;
function renderResults(users) {
  if (users.length === 0) {
    results.innerHTML = '<div class="px-2 py-6 text-center text-sm text-gray-400">No users found.</div>';
    return;
  }

  results.innerHTML = users
    .map((user) => {
      const avatarHtml = user.avatar_url
        ? `<img src="${escapeHtml(user.avatar_url)}" class="w-8 h-8 rounded-full object-cover" />`
        : `<div class="w-8 h-8 rounded-full bg-green-800 text-white text-xs flex items-center justify-center font-semibold">${escapeHtml(user.initials || "")}</div>`;

      const actionHtml = user.existing_game_session_id
        ? `<a href="/game_sessions/${user.existing_game_session_id}" class="text-xs font-medium text-green-800 bg-green-50 hover:bg-green-100 px-3 py-1.5 rounded-lg transition">Go to Game</a>`
        : `<button type="button" class="js-gameroom-invite-btn text-xs font-medium text-white bg-green-800 hover:bg-green-700 px-3 py-1.5 rounded-lg transition" data-user-id="${user.id}">Invite</button>`;

      return `
        <div class="flex items-center justify-between gap-2 px-2 py-2 rounded-lg hover:bg-gray-50">
          <div class="flex items-center gap-2 min-w-0">
            ${avatarHtml}
            <span class="text-sm text-gray-800 truncate">${escapeHtml(user.name)}</span>
          </div>
          ${actionHtml}
        </div>`;
    })
    .join("");
}

  function performSearch(query) {
    fetch("/search/gameroom_users?q=" + encodeURIComponent(query), { headers: { Accept: "application/json" } })
      .then((res) => (res.ok ? res.json() : null))
      .then((data) => { if (data) renderResults(data.results); })
      .catch((err) => console.error("Gameroom search error:", err));
  }

  input.addEventListener("input", () => {
    clearTimeout(debounceTimer);
    const query = input.value.trim();
    if (query.length < 1) {
      results.innerHTML = '<div class="px-2 py-6 text-center text-sm text-gray-400">Search for someone to invite</div>';
      return;
    }
    debounceTimer = setTimeout(() => performSearch(query), 150);
  });

  results.addEventListener("click", (e) => {
    const inviteBtn = e.target.closest(".js-gameroom-invite-btn");
    if (!inviteBtn) return;

    const userId = inviteBtn.dataset.userId;
    inviteBtn.disabled = true;

    fetch("/game_sessions", {
      method: "POST",
      headers: { "Content-Type": "application/json", "X-CSRF-Token": csrfToken(), Accept: "application/json" },
      body: JSON.stringify({ opponent_id: userId }),
    })
      .then((res) => res.json())
      .then(() => {
        inviteBtn.outerHTML = '<span class="text-xs text-gray-400 px-3 py-1.5">Invited</span>';
      })
      .catch((err) => {
        console.error("Invite error:", err);
        inviteBtn.disabled = false;
      });
  });
}

export function initAllGameroomPanels() {
  document.querySelectorAll('[id^="gameroom-btn-"]').forEach((btn) => {
    const suffix = btn.id.replace("gameroom-btn-", "");
    initGameroomPanel(suffix);
  });
}

// Global GameChannel subscription — same "subscribe once per user, not per
// page" pattern as CallChannel in call_session.js.
export function initGameChannel() {
  const currentUserId = document.body.dataset.currentUserId;
  if (!currentUserId) return;
  if (gameSubscription) return;

  gameConsumer = gameConsumer || createConsumer("/cable");
  gameSubscription = gameConsumer.subscriptions.create(
    { channel: "GameChannel" },
    {
      received(data) {
        if (data.type === "game_started") {
          window.location.href = "/game_sessions/" + data.game_session_id;
        }
        if (data.type === "game_declined") {
          console.log("Invite declined for game", data.game_session_id);
        }
      },
    }
  );
}