import { Controller } from "@hotwired/stimulus";
import { initFlexibleTextareas } from "flexible-textarea";

export default class extends Controller {
  connect() {
    // Initialize the flexible textarea library
    initFlexibleTextareas();

    // Override the resize behavior to preserve scroll position
    this.setupScrollPreservation();
  }

  setupScrollPreservation() {
    // Listen for input events that trigger resize
    this.element.addEventListener(
      "input",
      this.preserveScrollOnResize.bind(this)
    );
    this.element.addEventListener(
      "keydown",
      this.preserveScrollOnResize.bind(this)
    );
    this.element.addEventListener(
      "paste",
      this.preserveScrollOnResize.bind(this)
    );
  }

  preserveScrollOnResize() {
    // Store current scroll position
    const scrollTop = window.pageYOffset || document.documentElement.scrollTop;

    // Use requestAnimationFrame to run after the flexible-textarea library has resized
    requestAnimationFrame(() => {
      // Restore scroll position if it changed significantly (more than 5px)
      const currentScrollTop =
        window.pageYOffset || document.documentElement.scrollTop;
      if (Math.abs(currentScrollTop - scrollTop) > 5) {
        window.scrollTo(0, scrollTop);
      }
    });
  }
}
