import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.setupFlexibleTextarea();
  }

  setupFlexibleTextarea() {
    // Set initial height
    this.resize();

    // Add event listeners for input changes
    this.element.addEventListener("input", this.handleInput.bind(this));
    this.element.addEventListener("keydown", this.handleKeydown.bind(this));
    this.element.addEventListener("paste", this.handlePaste.bind(this));
  }

  handleInput() {
    this.resizeWithScrollPreservation();
  }

  handleKeydown(event) {
    // Handle Enter key specifically
    if (event.key === "Enter") {
      setTimeout(() => this.resizeWithScrollPreservation(), 0);
    }
  }

  handlePaste() {
    setTimeout(() => this.resizeWithScrollPreservation(), 0);
  }

  resizeWithScrollPreservation() {
    // Store current scroll position
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    // Perform the resize
    this.resize();

    // Restore scroll position immediately
    window.scrollTo(0, scrollTop);
  }

  resize() {
    // Reset height to auto to get accurate scrollHeight
    this.element.style.height = "auto";

    // Set new height based on content
    this.element.style.height = this.element.scrollHeight + "px";
  }
}
