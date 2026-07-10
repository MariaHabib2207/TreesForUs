// app/javascript/chat/message_form.js
// Owns the message composer: text submission, attachment previews, and the
// record-a-voice-note flow that swaps the input row for a recording row.

import { appendMessageRow, csrfToken } from "./dom_utils";

const MAX_RECORD_SECONDS = 120;

let mediaRecorder = null;
let mediaStream = null;
let chunks = [];
let recordSeconds = 0;
let recordTimerInterval = null;
let mimeType = null;
let recordedFile = null;
let recordingFinished = false;
let isSending = false;

function formatTime(s) {
  const m = Math.floor(s / 60);
  const sec = String(s % 60).padStart(2, "0");
  return `${m}:${sec}`;
}

function showSendError(msg) {
  let el = document.getElementById("send-error");
  if (!el) {
    el = document.createElement("div");
    el.id = "send-error";
    el.className =
      "text-xs text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-1.5 mb-2";
    const wrapper = document.getElementById("message-form")?.firstElementChild;
    if (wrapper) wrapper.prepend(el);
  }
  el.textContent = msg;
  el.classList.remove("hidden");
}

function clearSendError() {
  document.getElementById("send-error")?.classList.add("hidden");
}

export function initMessageForm() {
  const messageForm = document.getElementById("message-form");
  if (!messageForm) return;

  // Clone-and-replace to guarantee we never double-bind listeners across
  // repeated init() calls (e.g. Turbo navigations).
  const newForm = messageForm.cloneNode(true);
  messageForm.parentNode.replaceChild(newForm, messageForm);

  const newInput = document.getElementById("message-input");
  const newFileInput = document.getElementById("file-input");
  const newPreview = document.getElementById("attachment-preview");
  const newSendBtn = document.getElementById("send-btn");
  const durationInput = document.getElementById("duration-input");
  const voiceBtn = document.getElementById("voice-btn");
  const normalRow = document.getElementById("normal-input-row");
  const recordingRow = document.getElementById("recording-row");
  const stopBtn = document.getElementById("stop-recording-btn");
  const cancelBtn = document.getElementById("cancel-recording-btn");
  const recordingTimer = document.getElementById("recording-timer");

  function setControlsDisabled(disabled) {
    newSendBtn.disabled = disabled;
    voiceBtn.disabled = disabled;
    stopBtn.disabled = disabled;
    cancelBtn.disabled = disabled;
  }

  async function startRecording() {
    try {
      mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch (err) {
      alert("Microphone access is required to record a voice message.");
      return;
    }

    mimeType = MediaRecorder.isTypeSupported("audio/webm") ? "audio/webm" : "audio/mp4";
    mediaRecorder = new MediaRecorder(mediaStream, { mimeType });
    chunks = [];
    recordingFinished = false;

    mediaRecorder.ondataavailable = (e) => {
      if (e.data.size > 0) chunks.push(e.data);
    };
    mediaRecorder.onstop = finishRecording;
    mediaRecorder.start();

    recordSeconds = 0;
    recordingTimer.textContent = formatTime(recordSeconds);
    recordTimerInterval = setInterval(() => {
      recordSeconds++;
      recordingTimer.textContent = formatTime(recordSeconds);
      if (recordSeconds >= MAX_RECORD_SECONDS) stopRecording();
    }, 1000);

    clearSendError();
    normalRow.classList.add("hidden");
    normalRow.classList.remove("flex");
    recordingRow.classList.remove("hidden");
    recordingRow.classList.add("flex");
  }

  function stopRecording() {
    if (mediaRecorder && mediaRecorder.state !== "inactive") mediaRecorder.stop();
    if (mediaStream) mediaStream.getTracks().forEach((t) => t.stop());
    clearInterval(recordTimerInterval);
  }

  function cancelRecording() {
    recordingFinished = true;
    stopRecording();
    chunks = [];
    recordedFile = null;
    resetRecordingUI();
  }

  function resetRecordingUI() {
    recordSeconds = 0;
    recordingTimer.textContent = "0:00";
    recordingRow.classList.add("hidden");
    recordingRow.classList.remove("flex");
    normalRow.classList.remove("hidden");
    normalRow.classList.add("flex");
  }

  function finishRecording() {
    if (recordingFinished) return;
    recordingFinished = true;

    if (chunks.length === 0) {
      resetRecordingUI();
      return;
    }

    const ext = mimeType.includes("mp4") ? "m4a" : "webm";
    const blob = new Blob(chunks, { type: mimeType });
    recordedFile = new File([blob], `voice-${Date.now()}.${ext}`, { type: mimeType });

    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(recordedFile);
    newFileInput.files = dataTransfer.files;
    durationInput.value = recordSeconds;

    resetRecordingUI();
    newForm.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
  }

  voiceBtn.addEventListener("click", startRecording);
  stopBtn.addEventListener("click", stopRecording);
  cancelBtn.addEventListener("click", cancelRecording);

  newForm.addEventListener("submit", async function (e) {
    e.preventDefault();
    e.stopPropagation();

    if (isSending) return;

    const body = newInput.value.trim();
    if (!body && newFileInput.files.length === 0) return;

    isSending = true;
    setControlsDisabled(true);
    clearSendError();

    const formData = new FormData(newForm);
    const currentUserId = document.getElementById("messages-container")?.dataset.currentUserId;

    try {
      const response = await fetch(newForm.action, {
        method: "POST",
        headers: {
          "X-CSRF-Token": csrfToken(),
          Accept: "application/json",
        },
        body: formData,
      });

      if (response.ok) {
        const data = await response.json();
        if (data.message_html) {
          appendMessageRow(data.message_html, currentUserId, { forceStick: true });
        }

        newInput.value = "";
        newInput.style.height = "auto";
        newFileInput.value = "";
        durationInput.value = "";
        newPreview.innerHTML = "";
        newPreview.classList.add("hidden");
        newPreview.classList.remove("flex");
        recordedFile = null;
      } else {
        console.error("Send failed, status:", response.status);
        showSendError("Message failed to send. Tap send to try again.");
      }
    } catch (err) {
      console.error("Send error:", err);
      showSendError("Message failed to send. Check your connection and try again.");
    } finally {
      isSending = false;
      setControlsDisabled(false);
      newInput.focus();
    }
  });

  newInput.addEventListener("input", function () {
    this.style.height = "auto";
    this.style.height = Math.min(this.scrollHeight, 128) + "px";
  });

  newInput.addEventListener("keydown", function (e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      newForm.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    }
  });

  newFileInput.addEventListener("change", function () {
    if (recordedFile) return;
    newPreview.innerHTML = "";
    if (this.files.length === 0) {
      newPreview.classList.add("hidden");
      newPreview.classList.remove("flex");
      return;
    }
    newPreview.classList.remove("hidden");
    newPreview.classList.add("flex");
    Array.from(this.files).forEach((file) => {
      const chip = document.createElement("div");
      chip.className =
        "flex items-center gap-1.5 bg-white rounded-full pl-1 pr-3 py-1 shadow-sm text-xs text-gray-600 max-w-[160px]";
      if (file.type.startsWith("image/")) {
        const img = document.createElement("img");
        img.src = URL.createObjectURL(file);
        img.className = "w-6 h-6 rounded-full object-cover shrink-0";
        chip.appendChild(img);
        const name = document.createElement("span");
        name.className = "truncate";
        name.textContent = file.name;
        chip.appendChild(name);
      } else {
        chip.innerHTML = `<span>📎</span><span class="truncate">${file.name}</span>`;
      }
      newPreview.appendChild(chip);
    });
  });
}

// Exposed so the top-level lifecycle module can stop an in-flight
// recording on turbo:before-cache without recreating recorder internals.
export function stopRecordingIfActive() {
  if (mediaRecorder && mediaRecorder.state === "recording") {
    mediaRecorder.stop();
    if (mediaStream) mediaStream.getTracks().forEach((t) => t.stop());
  }
}
