class CustomAudioPlayer {
  constructor(container) {
    this.container = container;
    this.audio = container.querySelector("audio");
    this.playButton = container.querySelector(
      ".custom-audio-player__play-button"
    );
    this.progressBar = container.querySelector(
      ".custom-audio-player__progress-bar"
    );
    this.progressFill = container.querySelector(
      ".custom-audio-player__progress-bar-fill"
    );
    this.progressHandle = container.querySelector(
      ".custom-audio-player__progress-bar-handle"
    );
    this.timeDisplay = container.querySelector(".custom-audio-player__time");
    this.volumeButton = container.querySelector(
      ".custom-audio-player__volume-button"
    );
    this.volumeSlider = container.querySelector(
      ".custom-audio-player__volume-slider"
    );
    this.speedSelector = container.querySelector(
      ".custom-audio-player__speed-selector"
    );

    this.isPlaying = false;
    this.isDragging = false;

    this.init();
  }

  init() {
    console.log("CustomAudioPlayer init() called");
    this.bindEvents();
    this.updateTimeDisplay();
    this.updateVolumeIcon(); // This will set the initial volume icon state
    this.updateVolumeSlider(); // Add this line
  }

  bindEvents() {
    console.log("Binding events...");
    // Play/Pause
    this.playButton.addEventListener("click", () => this.togglePlay());

    // Progress bar
    this.progressBar.addEventListener("click", (e) => this.seek(e));
    this.progressHandle.addEventListener("mousedown", () =>
      this.startDragging()
    );
    document.addEventListener("mousemove", (e) => this.drag(e));
    document.addEventListener("mouseup", () => this.stopDragging());

    // Volume
    this.volumeButton.addEventListener("click", () => this.toggleMute());
    this.volumeSlider.addEventListener("input", (e) => {
      const volume = e.target.value / 100;
      this.audio.volume = volume;
      this.updateVolumeIcon();
      this.updateVolumeSlider(); // Add this line
    });

    // Speed
    this.speedSelector.addEventListener("change", (e) => {
      this.setPlaybackSpeed(e.target.value);
    });

    // Transcript button
    const transcriptButton = this.container.querySelector(
      ".custom-audio-player__transcript-button"
    );
    const transcriptContent = this.container.querySelector(
      ".custom-audio-player__transcript-content"
    );

    if (transcriptButton && transcriptContent) {
      transcriptButton.addEventListener("click", () => {
        transcriptContent.classList.toggle("show");
        transcriptButton.classList.toggle("active");
      });
    }

    // Audio events
    this.audio.addEventListener("timeupdate", () => this.updateProgress());
    this.audio.addEventListener("loadedmetadata", () => {
      console.log("Audio metadata loaded, duration:", this.audio.duration);
      this.updateTimeDisplay();
    });
    this.audio.addEventListener("canplay", () => {
      console.log("Audio can play, duration:", this.audio.duration);
    });
    this.audio.addEventListener("ended", () => this.onEnded());
    this.audio.addEventListener("error", (e) => {
      console.error("Audio error:", e);
    });
    console.log("Events bound successfully");
  }

  togglePlay() {
    console.log("togglePlay called, isPlaying:", this.isPlaying);
    if (this.isPlaying) {
      this.pause();
    } else {
      this.play();
    }
  }

  play() {
    console.log("play() called");
    this.audio.play();
    this.isPlaying = true;
    this.playButton.classList.add("playing");
  }

  pause() {
    console.log("pause() called");
    this.audio.pause();
    this.isPlaying = false;
    this.playButton.classList.remove("playing");
  }

  seek(e) {
    if (this.isDragging) return;

    const rect = this.progressBar.getBoundingClientRect();
    const clickX = e.clientX - rect.left;
    const percentage = clickX / rect.width;

    // Only seek if audio has duration
    if (this.audio.duration && this.audio.duration > 0) {
      const newTime = percentage * this.audio.duration;
      console.log("Seeking to:", newTime, "seconds");
      this.audio.currentTime = newTime;
    } else {
      console.log("Audio not ready, duration:", this.audio.duration);
    }
  }

  startDragging() {
    this.isDragging = true;
  }

  drag(e) {
    if (!this.isDragging) return;

    const rect = this.progressBar.getBoundingClientRect();
    const dragX = Math.max(0, Math.min(e.clientX - rect.left, rect.width));
    const percentage = dragX / rect.width;

    // Only seek if audio has duration
    if (this.audio.duration && this.audio.duration > 0) {
      const newTime = percentage * this.audio.duration;
      this.audio.currentTime = newTime;
    }
  }

  stopDragging() {
    this.isDragging = false;
  }

  updateProgress() {
    if (this.audio.duration) {
      const percentage = (this.audio.currentTime / this.audio.duration) * 100;
      this.progressFill.style.width = `${percentage}%`;
      this.progressHandle.style.left = `${percentage}%`;
    }
  }

  updateTimeDisplay() {
    if (this.audio.duration) {
      const current = this.formatTime(this.audio.currentTime);
      const total = this.formatTime(this.audio.duration);
      this.timeDisplay.textContent = `${current} / ${total}`;
    }
  }

  formatTime(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, "0")}`;
  }

  toggleMute() {
    this.audio.muted = !this.audio.muted;
    this.updateVolumeIcon();
  }

  setVolume(value) {
    this.audio.volume = value / 100;
    this.audio.muted = false;
    this.updateVolumeIcon();
  }

  setPlaybackSpeed(speed) {
    const speedValue = parseFloat(speed);
    this.audio.playbackRate = speedValue;
    console.log("Playback speed set to:", speedValue + "x");
  }

  updateVolumeIcon() {
    // Remove all volume state classes
    this.volumeButton.classList.remove(
      "volume-muted",
      "volume-low",
      "volume-high"
    );

    if (this.audio.muted || this.audio.volume === 0) {
      this.volumeButton.classList.add("volume-muted");
    } else {
      this.volumeButton.classList.add("volume-high");
    }
  }

  updateVolumeSlider() {
    const percentage = (this.audio.volume / 1) * 100;
    const fillColor = this.getComputedStyle("--action-color", "#1246ff");
    const trackColor = this.hexToRgba(
      this.getComputedStyle("--action-color", "#1246ff"),
      0.25
    );
    this.volumeSlider.value = percentage;

    // Update the filled portion using gradient
    this.volumeSlider.style.background = `linear-gradient(to right, ${fillColor} 0%, ${fillColor} ${percentage}%, ${trackColor} ${percentage}%, ${trackColor} 100%)`;
  }

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

  onEnded() {
    this.pause();
    this.progressFill.style.width = "0%";
    this.progressHandle.style.left = "0%";
  }
}

// Initialize all custom audio players on the page
document.addEventListener("DOMContentLoaded", () => {
  const audioPlayers = document.querySelectorAll(".custom-audio-player");
  audioPlayers.forEach((player) => new CustomAudioPlayer(player));
});
