// app/javascript/chat/add_people.js
// "Add people" modal: toggling visibility and posting invite requests.

import { csrfToken, messagesContainer } from "./dom_utils";

export function initAddPeople() {
  const modal = document.getElementById("add-people-modal");
  const openBtn = document.getElementById("add-people-btn");
  const closeBtn = document.getElementById("close-add-people-btn");
  if (!modal || !openBtn) return;

  openBtn.addEventListener("click", () => {
    modal.classList.remove("hidden");
    modal.classList.add("flex");
  });

  closeBtn?.addEventListener("click", () => {
    modal.classList.add("hidden");
    modal.classList.remove("flex");
  });

  modal.addEventListener("click", (e) => {
    if (e.target === modal) {
      modal.classList.add("hidden");
      modal.classList.remove("flex");
    }
  });

  modal.querySelectorAll(".invite-friend-btn").forEach((btn) => {
    btn.addEventListener("click", async function () {
      if (this.disabled) return;
      this.disabled = true;
      const originalText = this.textContent;
      this.textContent = "Sending...";

      const chatroomId = messagesContainer()?.dataset.chatroomId;

      try {
        const response = await fetch(`/chatrooms/${chatroomId}/invite_member`, {
          method: "POST",
          headers: {
            "X-CSRF-Token": csrfToken(),
            "Content-Type": "application/json",
            Accept: "application/json",
          },
          body: JSON.stringify({ recipient_id: this.dataset.recipientId }),
        });

        if (response.ok) {
          this.textContent = "Sent";
        } else {
          this.textContent = originalText;
          this.disabled = false;
        }
      } catch (err) {
        console.error("Invite error:", err);
        this.textContent = originalText;
        this.disabled = false;
      }
    });
  });
}
