import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { audioSrc: String };

  connect() {
    console.log("Audio duration controller connected");
    console.log("Audio src:", this.audioSrcValue);
    this.loadAudioDuration();
  }

  loadAudioDuration() {
    if (!this.audioSrcValue) {
      console.log("No audio source provided");
      return;
    }

    console.log("Loading audio duration for:", this.audioSrcValue);
    const audio = new Audio();

    audio.addEventListener("loadedmetadata", () => {
      console.log("Audio metadata loaded, duration:", audio.duration);
      if (audio.duration && audio.duration > 0) {
        const minutes = Math.floor(audio.duration / 60);
        const seconds = Math.floor(audio.duration % 60);
        const formattedDuration = `${minutes}:${seconds
          .toString()
          .padStart(2, "0")}`;
        console.log("Setting duration to:", formattedDuration);
        this.element.textContent = formattedDuration;
      }
    });

    audio.addEventListener("error", (e) => {
      console.log("Audio loading error:", e);
      // If audio fails to load, keep showing 0:00
      this.element.textContent = "0:00";
    });

    // Start loading the audio file
    console.log("Setting audio src to:", this.audioSrcValue);
    audio.src = this.audioSrcValue;
  }
}
