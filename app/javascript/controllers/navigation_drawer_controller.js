import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="navigation-drawer"
export default class extends Controller {
  static classes = ["open", "closed"];
  static targets = ["overlay"];

  connect() {
    console.log("Navigation drawer controller connected");
    // Start in closed state
    this.close();
  }

  open() {
    this.element.classList.remove(this.closedClass);
    this.element.classList.add(this.openClass);
  }

  close() {
    this.element.classList.remove(this.openClass);
    this.element.classList.add(this.closedClass);
  }

  toggle() {
    console.log(
      "Toggle called, current classes:",
      this.element.classList.toString()
    );
    if (this.element.classList.contains(this.openClass)) {
      console.log("Closing drawer");
      this.close();
    } else {
      console.log("Opening drawer");
      this.open();
    }
  }

  // Close when clicking on overlay background
  overlayClick(event) {
    if (event.target === this.overlayTarget) {
      this.close();
    }
  }

  // Close on escape key
  keydown(event) {
    if (event.key === "Escape") {
      this.close();
    }
  }
}
