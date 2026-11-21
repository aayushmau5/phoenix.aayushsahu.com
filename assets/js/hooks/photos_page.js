import { takeSharedPhotos } from "../share_target";

const hasFiles = (event) =>
  Array.from(event.dataTransfer?.types || []).includes("Files");

const isTyping = (target) => target.closest?.("input, textarea") != null;

const PhotosPage = {
  mounted() {
    this.overlay = this.el.querySelector("#photos-drop-overlay");
    this.dragDepth = 0;

    this.listeners = [
      [window, "dragenter", (e) => this.onDragEnter(e)],
      [window, "dragover", (e) => hasFiles(e) && e.preventDefault()],
      [window, "dragleave", (e) => this.onDragLeave(e)],
      [window, "drop", (e) => this.onDrop(e)],
      [window, "paste", (e) => this.onPaste(e)],
      [window, "keydown", (e) => this.onKeyDown(e)],
      [this.el, "touchstart", (e) => this.onTouchStart(e)],
      [this.el, "touchend", (e) => this.onTouchEnd(e)],
    ];

    this.listeners.forEach(([target, name, handler]) =>
      target.addEventListener(name, handler),
    );

    this.uploadSharedPhotos();
  },

  async uploadSharedPhotos() {
    if (!new URLSearchParams(window.location.search).has("shared")) return;
    const photos = await takeSharedPhotos();
    if (photos.length > 0) this.upload("photos", photos);
  },

  destroyed() {
    this.listeners.forEach(([target, name, handler]) =>
      target.removeEventListener(name, handler),
    );
  },

  panelOpen() {
    return this.el.querySelector("#photo-panel") != null;
  },

  showOverlay(show) {
    this.overlay.classList.toggle("hidden", !show);
    this.overlay.classList.toggle("flex", show);
  },

  onDragEnter(e) {
    if (!hasFiles(e)) return;
    e.preventDefault();
    this.dragDepth += 1;
    this.showOverlay(true);
  },

  onDragLeave(e) {
    if (!hasFiles(e)) return;
    this.dragDepth = Math.max(0, this.dragDepth - 1);
    if (this.dragDepth === 0) this.showOverlay(false);
  },

  onDrop(e) {
    if (!hasFiles(e)) return;
    e.preventDefault();
    this.dragDepth = 0;
    this.showOverlay(false);
    this.upload("photos", e.dataTransfer.files);
  },

  onPaste(e) {
    const images = Array.from(e.clipboardData?.files || []).filter((file) =>
      file.type.startsWith("image/"),
    );
    if (images.length === 0) return;
    e.preventDefault();
    this.upload("photos", images);
  },

  onKeyDown(e) {
    if (!this.panelOpen()) return;

    if (e.key === "Escape") {
      e.target.blur?.();
      this.pushEvent("close_panel", {});
    } else if (!isTyping(e.target) && ["ArrowLeft", "ArrowRight"].includes(e.key)) {
      e.preventDefault();
      this.pushEvent("select_adjacent", {
        dir: e.key === "ArrowRight" ? "next" : "prev",
      });
    }
  },

  onTouchStart(e) {
    const inPanel = e.target.closest("#photo-panel");
    if (!inPanel || isTyping(e.target)) return;
    const touch = e.touches[0];
    this.touchStart = { x: touch.clientX, y: touch.clientY };
  },

  onTouchEnd(e) {
    if (!this.touchStart) return;
    const touch = e.changedTouches[0];
    const dx = touch.clientX - this.touchStart.x;
    const dy = touch.clientY - this.touchStart.y;
    this.touchStart = null;

    if (Math.abs(dx) > 60 && Math.abs(dx) > Math.abs(dy)) {
      this.pushEvent("select_adjacent", { dir: dx < 0 ? "next" : "prev" });
    } else if (dy > 80 && Math.abs(dy) > Math.abs(dx)) {
      this.pushEvent("close_panel", {});
    }
  },
};

export default PhotosPage;
