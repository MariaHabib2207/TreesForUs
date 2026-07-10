// app/javascript/chat/voice_player.js
// Custom playback UI for recorded voice notes rendered inside message rows.
// Only one voice note plays at a time; starting another pauses the last.

import { formatDuration, messagesContainer } from "./dom_utils";

let activeVoiceAudio = null;
let activeVoicePlayer = null;

function resetPlayerUI(player) {
  const playIcon = player.querySelector(".icon-play");
  const pauseIcon = player.querySelector(".icon-pause");
  const fill = player.querySelector(".voice-note-progress-fill");
  const handle = player.querySelector(".voice-note-progress-handle");
  if (playIcon) playIcon.classList.remove("hidden");
  if (pauseIcon) pauseIcon.classList.add("hidden");
  if (fill) fill.style.width = "0%";
  if (handle) handle.style.left = "0%";
}

export function stopActiveVoiceAudio() {
  if (activeVoiceAudio) activeVoiceAudio.pause();
  if (activeVoicePlayer) resetPlayerUI(activeVoicePlayer);
  activeVoiceAudio = null;
  activeVoicePlayer = null;
}

function getOrCreateAudio(player) {
  let audio = player._audioEl;
  if (audio) return audio;

  audio = new Audio(player.dataset.audioSrc);
  audio.preload = "metadata";
  player._audioEl = audio;

  const durationEl = player.querySelector(".voice-note-duration");
  const fill = player.querySelector(".voice-note-progress-fill");
  const handle = player.querySelector(".voice-note-progress-handle");
  const playIcon = player.querySelector(".icon-play");
  const pauseIcon = player.querySelector(".icon-pause");

  audio.addEventListener("loadedmetadata", () => {
    if (durationEl && durationEl.dataset.hasServerDuration !== "true" && isFinite(audio.duration)) {
      durationEl.textContent = formatDuration(audio.duration);
    }
  });

  audio.addEventListener("timeupdate", () => {
    if (!audio.duration || !isFinite(audio.duration)) return;
    const pct = (audio.currentTime / audio.duration) * 100;
    if (fill) fill.style.width = `${pct}%`;
    if (handle) handle.style.left = `${pct}%`;
    if (durationEl) durationEl.textContent = formatDuration(audio.duration - audio.currentTime);
  });

  audio.addEventListener("ended", () => {
    resetPlayerUI(player);
    if (durationEl && isFinite(audio.duration)) {
      durationEl.textContent = formatDuration(audio.duration);
    }
    if (activeVoiceAudio === audio) {
      activeVoiceAudio = null;
      activeVoicePlayer = null;
    }
  });

  audio.addEventListener("play", () => {
    if (playIcon) playIcon.classList.add("hidden");
    if (pauseIcon) pauseIcon.classList.remove("hidden");
  });

  audio.addEventListener("pause", () => {
    if (playIcon) playIcon.classList.remove("hidden");
    if (pauseIcon) pauseIcon.classList.add("hidden");
  });

  return audio;
}

export function initVoicePlayers() {
  const container = messagesContainer();
  if (!container || container._voicePlayersInit) return;
  container._voicePlayersInit = true;

  container.addEventListener("click", function (e) {
    const playBtn = e.target.closest(".voice-play-btn");
    const track = e.target.closest(".voice-note-progress");

    if (playBtn) {
      const player = playBtn.closest(".voice-note-player");
      if (!player) return;
      const audio = getOrCreateAudio(player);

      if (activeVoiceAudio && activeVoiceAudio !== audio) stopActiveVoiceAudio();

      if (audio.paused) {
        audio.play();
        activeVoiceAudio = audio;
        activeVoicePlayer = player;
      } else {
        audio.pause();
        if (activeVoiceAudio === audio) {
          activeVoiceAudio = null;
          activeVoicePlayer = null;
        }
      }
      return;
    }

    if (track) {
      const player = track.closest(".voice-note-player");
      if (!player) return;
      const audio = getOrCreateAudio(player);
      if (!audio.duration || !isFinite(audio.duration)) return;

      const rect = track.getBoundingClientRect();
      const ratio = Math.min(Math.max((e.clientX - rect.left) / rect.width, 0), 1);
      audio.currentTime = ratio * audio.duration;
    }
  });
}
