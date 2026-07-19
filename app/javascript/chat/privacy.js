// app/javascript/chat/privacy.js
function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content;
}

export function initPrivacyToggles() {
  const blurBtn = document.getElementById("blur-toggle-btn");
  const overlay = document.getElementById("chat-blur-overlay");

  blurBtn?.addEventListener("click", async () => {
    const chatroomId = blurBtn.dataset.chatroomId;
    const res = await fetch(`/chatrooms/${chatroomId}/toggle_blur`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
    });
    if (!res.ok) return;
    window.location.reload(); // simplest correct re-render of the overlay state
  });

  overlay?.addEventListener("click", async () => {
    const chatroomId = overlay.dataset.chatroomId;
    await fetch(`/chatrooms/${chatroomId}/toggle_blur`, {
      method: "PATCH",
      headers: { "X-CSRF-Token": csrfToken(), Accept: "application/json" },
    });
    overlay.remove();
  });
}