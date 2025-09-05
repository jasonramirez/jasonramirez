import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    this.fieldTarget.addEventListener("input", this.forceLowercase.bind(this));
  }

  disconnect() {
    this.fieldTarget.removeEventListener(
      "input",
      this.forceLowercase.bind(this)
    );
  }

  forceLowercase(event) {
    const input = event.target;
    const start = input.selectionStart;
    const end = input.selectionEnd;

    input.value = input.value.toLowerCase();

    // Restore cursor position
    input.setSelectionRange(start, end);
  }
}
