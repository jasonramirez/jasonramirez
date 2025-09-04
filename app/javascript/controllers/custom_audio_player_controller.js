import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "audio",
    "playButton",
    "progressBar",
    "progressFill",
    "progressHandle",
    "timeDisplay",
    "volumeButton",
    "volumeSlider",
    "speedSelector",
    "transcriptButton",
    "transcriptContent",
  ];

  static values = {
    audioSrc: String,
    preload: { type: String, default: "metadata" },
  };

  connect() {
    this.isPlaying = false;
    this.isDragging = false;

    this.initializeAudio();
    this.bindEvents();
    this.updateTimeDisplay();
    this.updateVolumeIcon();
    this.updateVolumeSlider();
  }

  disconnect() {
    this.cleanup();
  }

  initializeAudio() {
    if (this.audioSrcValue) {
      this.audioTarget.src = this.audioSrcValue;
    }

    this.audioTarget.preload = this.preloadValue;

    // Ensure audio is ready
    if (this.audioTarget.readyState >= 2) {
      this.updateTimeDisplay();
    }
  }

  bindEvents() {
    // Audio events
    this.audioTarget.addEventListener(
      "timeupdate",
      this.updateProgress.bind(this)
    );
    this.audioTarget.addEventListener(
      "loadedmetadata",
      this.updateTimeDisplay.bind(this)
    );
    this.audioTarget.addEventListener("canplay", this.onCanPlay.bind(this));
    this.audioTarget.addEventListener("ended", this.onEnded.bind(this));
    this.audioTarget.addEventListener("error", this.onError.bind(this));
    this.audioTarget.addEventListener("loadstart", this.onLoadStart.bind(this));
    this.audioTarget.addEventListener(
      "loadeddata",
      this.onLoadedData.bind(this)
    );

    // Document events for dragging
    document.addEventListener("mousemove", this.drag.bind(this));
    document.addEventListener("mouseup", this.stopDragging.bind(this));
  }

  cleanup() {
    // Remove event listeners
    document.removeEventListener("mousemove", this.drag.bind(this));
    document.removeEventListener("mouseup", this.stopDragging.bind(this));
  }

  // Playback controls
  togglePlay() {
    if (this.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  play() {
    const playPromise = this.audioTarget.play();

    if (playPromise !== undefined) {
      playPromise
        .then(() => {
          this.isPlaying = true;
          this.playButtonTarget.classList.add("playing");
        })
        .catch((error) => {
          console.error("Error playing audio:", error);
          this.onError(error);
        });
    }
  }

  pause() {
    this.audioTarget.pause();
    this.isPlaying = false;
    this.playButtonTarget.classList.remove("playing");
  }

  // Progress bar controls
  seek(event) {
    if (this.isDragging) return;

    const rect = this.progressBarTarget.getBoundingClientRect();
    const clickX = event.clientX - rect.left;
    const percentage = clickX / rect.width;

    this.seekToPercentage(percentage);
  }

  startDragging() {
    this.isDragging = true;
  }

  drag(event) {
    if (!this.isDragging) return;

    const rect = this.progressBarTarget.getBoundingClientRect();
    const dragX = Math.max(0, Math.min(event.clientX - rect.left, rect.width));
    const percentage = dragX / rect.width;

    this.seekToPercentage(percentage);
  }

  stopDragging() {
    this.isDragging = false;
  }

  seekToPercentage(percentage) {
    if (this.audioTarget.duration && this.audioTarget.duration > 0) {
      const newTime = percentage * this.audioTarget.duration;
      this.audioTarget.currentTime = newTime;
    }
  }

  updateProgress() {
    if (this.audioTarget.duration && this.audioTarget.duration > 0) {
      const percentage =
        (this.audioTarget.currentTime / this.audioTarget.duration) * 100;
      this.progressFillTarget.style.width = `${percentage}%`;
      this.progressHandleTarget.style.left = `${percentage}%`;
    }
  }

  // Time display
  updateTimeDisplay() {
    if (this.audioTarget.duration && this.audioTarget.duration > 0) {
      const current = this.formatTime(this.audioTarget.currentTime);
      const total = this.formatTime(this.audioTarget.duration);
      this.timeDisplayTarget.textContent = `${current} / ${total}`;
    } else {
      this.timeDisplayTarget.textContent = "0:00 / 0:00";
    }
  }

  formatTime(seconds) {
    if (isNaN(seconds) || !isFinite(seconds)) return "0:00";

    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  }

  // Volume controls
  toggleMute() {
    this.audioTarget.muted = !this.audioTarget.muted;
    this.updateVolumeIcon();
  }

  setVolume(event) {
    const volume = event.target.value / 100;
    this.audioTarget.volume = volume;
    this.audioTarget.muted = false;
    this.updateVolumeIcon();
    this.updateVolumeSlider();
  }

  updateVolumeIcon() {
    // Remove all volume state classes
    this.volumeButtonTarget.classList.remove(
      "volume-muted",
      "volume-low",
      "volume-high"
    );

    if (this.audioTarget.muted || this.audioTarget.volume === 0) {
      this.volumeButtonTarget.classList.add("volume-muted");
    } else {
      this.volumeButtonTarget.classList.add("volume-high");
    }
  }

  updateVolumeSlider() {
    const percentage = (this.audioTarget.volume / 1) * 100;
    const fillColor = this.getComputedStyle("--action-color", "#1246ff");
    const trackColor = this.hexToRgba(
      this.getComputedStyle("--action-color", "#1246ff"),
      0.25
    );
    this.volumeSliderTarget.value = percentage;

    // Update the filled portion using gradient
    this.volumeSliderTarget.style.background = `linear-gradient(to right, ${fillColor} 0%, ${fillColor} ${percentage}%, ${trackColor} ${percentage}%, ${trackColor} 100%)`;
  }

  // Speed controls
  setPlaybackSpeed(event) {
    const speedValue = parseFloat(event.target.value);
    this.audioTarget.playbackRate = speedValue;
  }

  // Transcript controls
  toggleTranscript() {
    if (this.hasTranscriptContentTarget) {
      this.transcriptContentTarget.classList.toggle("show");
      this.transcriptButtonTarget.classList.toggle("active");
    }
  }

  // Audio event handlers
  onCanPlay() {
    // Audio is ready to play
    this.updateTimeDisplay();
  }

  onEnded() {
    this.pause();
    this.progressFillTarget.style.width = "0%";
    this.progressHandleTarget.style.left = "0%";
  }

  onError(error) {
    console.error("Audio error:", error);
    // Could add user-facing error handling here
  }

  onLoadStart() {
    // Audio loading started
    this.updateTimeDisplay();
  }

  onLoadedData() {
    // Audio data loaded
    this.updateTimeDisplay();
  }

  // Utility methods
  hexToRgba(hex, opacity) {
    // Remove the # if present
    hex = hex.replace("#", "");

    // Parse the hex values
    const r = parseInt(hex.substr(0, 2), 16);
    const g = parseInt(hex.substr(2, 2), 16);
    const b = parseInt(hex.substr(4, 2), 16);

    return `rgba(${r}, ${g}, ${b}, ${opacity})`;
  }

  getComputedStyle(property, fallback) {
    const value = getComputedStyle(document.documentElement).getPropertyValue(
      property
    );
    return value || fallback;
  }
}
