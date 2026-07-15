// app/javascript/chat/video_layout.js
// Draggable PiP + tap-to-swap for the video call overlay, WhatsApp-style.
//
// #video-call-overlay is `fixed inset-0`, so it's already the positioning
// context for its absolutely-positioned children — no extra wrapper needed.
//
// IMPORTANT: srcObject assignment never changes. #remote-video always gets
// the peer's stream (pc.ontrack), #local-video always gets your own
// (attachLocalPreview) — that's fixed by id in call_session.js. "Swapping"
// here only swaps which element LOOKS big (main) vs. small (pip); it's a
// pure class/style swap, not a stream reassignment.
//
// Mirroring is purely cosmetic and purely local: it flips #local-video via
// CSS (transform: scaleX(-1)) so your own self-view feels like looking in
// a mirror. It never touches the actual MediaStream, so the remote party
// always sees you the true, unmirrored way regardless of this setting.

const PIP_MARGIN = 16;
const DRAG_THRESHOLD_PX = 6;

const MAIN_CLASSES = "absolute inset-0 w-full h-full object-cover";
const PIP_CLASSES =
  "absolute w-24 h-32 sm:w-32 sm:h-44 rounded-2xl object-cover shadow-lg ring-2 ring-white/20 bg-black z-10 cursor-grab touch-none video-pip";

let overlay = null; // #video-call-overlay doubles as the drag stage
let isSwapped = false;
let pipPos = null; // { left, top } in px, relative to overlay
let dragState = null;
let bound = false;
let localMirrored = true; // front camera mirrors like a real mirror; back camera doesn't

function mainVideoEl() {
  return document.getElementById(isSwapped ? "local-video" : "remote-video");
}
function pipVideoEl() {
  return document.getElementById(isSwapped ? "remote-video" : "local-video");
}

// Applies the right class list to an element while preserving a
// pre-existing "hidden" class (attachLocalPreview toggles that
// independently when there's no camera track) and the mirror class on
// #local-video specifically (mirroring is about which camera, not role).
function setClasses(el, classString) {
  if (!el) return;
  const wasHidden = el.classList.contains("hidden");
  const isLocal = el.id === "local-video";
  const mirrorClass = isLocal && localMirrored ? " video-mirrored" : "";
  el.className = classString + (wasHidden ? " hidden" : "") + mirrorClass;
}

// A video that was previously dragged as the PiP carries inline
// left/top/right/bottom from positionPip(). Inline styles beat classes, so
// if that same element becomes the MAIN video, those leftover coordinates
// would fight the `inset-0` main classes and shove it off-screen. Clear
// them explicitly whenever an element takes the main role.
function clearInlinePosition(el) {
  if (!el) return;
  el.style.left = "";
  el.style.top = "";
  el.style.right = "";
  el.style.bottom = "";
}

function defaultPipPos() {
  const pip = pipVideoEl();
  if (!overlay || !pip) return { left: PIP_MARGIN, top: PIP_MARGIN };
  const rect = overlay.getBoundingClientRect();
  const pipW = pip.offsetWidth || 96;
  const pipH = pip.offsetHeight || 128;
  // Matches the original bottom-28 (≈112px) right-4 (16px) corner.
  return {
    left: rect.width - pipW - PIP_MARGIN,
    top: rect.height - pipH - 112,
  };
}

function clamp(pos) {
  const pip = pipVideoEl();
  if (!overlay || !pip) return pos;
  const rect = overlay.getBoundingClientRect();
  const pipW = pip.offsetWidth;
  const pipH = pip.offsetHeight;
  return {
    left: Math.min(Math.max(pos.left, PIP_MARGIN), Math.max(rect.width - pipW - PIP_MARGIN, PIP_MARGIN)),
    top: Math.min(Math.max(pos.top, PIP_MARGIN), Math.max(rect.height - pipH - PIP_MARGIN, PIP_MARGIN)),
  };
}

function positionPip() {
  const pip = pipVideoEl();
  if (!pip) return;
  if (!pipPos) pipPos = defaultPipPos();
  pipPos = clamp(pipPos);
  pip.style.left = `${pipPos.left}px`;
  pip.style.top = `${pipPos.top}px`;
  pip.style.right = "auto";
  pip.style.bottom = "auto";
}

function applyRoles() {
  const main = mainVideoEl();
  const pip = pipVideoEl();

  // Order matters: clear the incoming main video's leftover PiP
  // coordinates BEFORE/AFTER setting its classes — do both to be safe
  // regardless of which runs first.
  clearInlinePosition(main);
  setClasses(main, MAIN_CLASSES);
  clearInlinePosition(main);

  setClasses(pip, PIP_CLASSES);
  positionPip();
}

function swap() {
  isSwapped = !isSwapped;
  pipPos = null; // snaps back to the default corner on swap, like WhatsApp
  applyRoles();
}

// ---- mirroring ----

// Call from call_session.js whenever the local camera's facing mode
// changes (initial acquire, or after flipCamera()). Front ("user") camera
// mirrors like a real mirror; back ("environment") camera does not.
// Only ever touches #local-video's CSS class — never the transmitted
// MediaStream, so the remote party's view is unaffected.
export function setLocalMirrored(isMirrored) {
  localMirrored = !!isMirrored;
  const local = document.getElementById("local-video");
  if (!local) return;
  local.classList.toggle("video-mirrored", localMirrored);
}

// ---- pointer (mouse + touch) drag handling ----

function onPointerDown(e) {
  const pip = pipVideoEl();
  if (!pip || (e.target !== pip && !pip.contains(e.target))) return;

  const rect = overlay.getBoundingClientRect();
  const pipRect = pip.getBoundingClientRect();
  dragState = {
    pointerId: e.pointerId,
    startX: e.clientX,
    startY: e.clientY,
    originLeft: pipRect.left - rect.left,
    originTop: pipRect.top - rect.top,
    moved: false,
  };
  pip.setPointerCapture(e.pointerId);
  pip.classList.add("video-pip-dragging");
}

function onPointerMove(e) {
  if (!dragState || e.pointerId !== dragState.pointerId) return;
  const dx = e.clientX - dragState.startX;
  const dy = e.clientY - dragState.startY;
  if (Math.abs(dx) > DRAG_THRESHOLD_PX || Math.abs(dy) > DRAG_THRESHOLD_PX) dragState.moved = true;
  pipPos = clamp({ left: dragState.originLeft + dx, top: dragState.originTop + dy });
  positionPip();
}

function onPointerUp(e) {
  if (!dragState || e.pointerId !== dragState.pointerId) return;
  const pip = pipVideoEl();
  const wasDrag = dragState.moved;
  pip?.classList.remove("video-pip-dragging");
  try {
    pip?.releasePointerCapture(dragState.pointerId);
  } catch (_) {
    // already released — ignore
  }
  dragState = null;
  if (!wasDrag) swap(); // tap, not a drag -> swap main/pip
}

// Binds listeners once. Safe to call every time initCallControls() runs.
export function initVideoLayout() {
  if (bound) return;
  overlay = document.getElementById("video-call-overlay");
  if (!overlay) return;
  bound = true;

  overlay.addEventListener("pointerdown", onPointerDown);
  overlay.addEventListener("pointermove", onPointerMove);
  overlay.addEventListener("pointerup", onPointerUp);
  overlay.addEventListener("pointercancel", onPointerUp);
  window.addEventListener("resize", () => {
    if (pipPos) positionPip();
  });
}

// Call whenever the video overlay is (re)shown or torn down, so each call
// starts remote-as-main / local-as-pip in the default bottom-right corner.
export function resetVideoLayout() {
  isSwapped = false;
  pipPos = null;
  dragState = null;
  localMirrored = true; // every new call starts on the front camera
  overlay = overlay || document.getElementById("video-call-overlay");
  if (!overlay) return;

  // Clear any stale inline positioning on BOTH elements from a previous
  // call before reapplying default roles — otherwise old drag coordinates
  // can leak into the new call for a frame.
  clearInlinePosition(document.getElementById("remote-video"));
  clearInlinePosition(document.getElementById("local-video"));

  applyRoles();
}