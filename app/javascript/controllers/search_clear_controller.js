import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "clearButton"];

  connect() {
    this.toggleClearButton();
  }

  inputChanged() {
    this.toggleClearButton();
  }

  toggleClearButton() {
    if (this.inputTarget.value.trim().length > 0) {
      this.clearButtonTarget.style.display = "flex";
    } else {
      this.clearButtonTarget.style.display = "none";
    }
  }
}
