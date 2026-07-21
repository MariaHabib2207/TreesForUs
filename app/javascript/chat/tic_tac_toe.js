// app/javascript/chat/tic_tac_toe.js
// Tic-Tac-Toe board page: click-to-move + live board sync via GameChannel,
// scoped to this specific game session.

import { createConsumer } from "@rails/actioncable";
import { csrfToken } from "./dom_utils";

function init() {
  const wrap = document.querySelector(".tic-tac-toe-wrap");
  if (!wrap) return;
  if (wrap.dataset.tttInit === "true") return;
  wrap.dataset.tttInit = "true";

  const gameId = wrap.dataset.gameId;
  const mySymbol = wrap.dataset.symbol;
  const opponentName = wrap.dataset.opponentName || "your opponent";
  const board = document.getElementById("ttt-board");
  const statusEl = document.getElementById("ttt-status");
  if (!board) return;

  board.addEventListener("click", (e) => {
    const cell = e.target.closest(".ttt-cell");
    if (!cell || cell.disabled) return;

    fetch(`/game_sessions/${gameId}/move`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken(),
        Accept: "application/json",
      },
      body: JSON.stringify({ index: cell.dataset.index }),
    }).catch((err) => console.error("Move error:", err));
  });

  const consumer = createConsumer("/cable");
  consumer.subscriptions.create(
    { channel: "GameChannel", game_session_id: gameId },
    {
      received(data) {
        if (data.type === "game_started") {
          window.location.reload();
          return;
        }

        if (data.type !== "move_made") return;

        const isMyTurn = data.status === "active" && data.turn === mySymbol;

        const cells = document.querySelectorAll(".ttt-cell");
        data.board.split("").forEach((val, i) => {
          cells[i].textContent = val === "-" ? "" : val;
          cells[i].disabled = val !== "-" || !isMyTurn;
        });

        board.classList.toggle("pointer-events-none", !isMyTurn);
        board.classList.toggle("opacity-70", !isMyTurn);

        if (statusEl) {
          if (data.status === "active") {
            statusEl.textContent = isMyTurn ? "Your turn" : `${opponentName}'s turn`;
          } else if (data.status === "finished") {
            if (data.winner_id) {
              statusEl.textContent = String(data.winner_id) === wrap.dataset.userId
                ? "You won! 🎉"
                : "You lost";
            } else {
              statusEl.textContent = "It's a draw";
            }
          }
        }
      },
    }
  );
}

document.addEventListener("turbo:load", init);
document.addEventListener("DOMContentLoaded", init);