import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["title", "text"];

  connect() {}

  async share(event) {
    event.preventDefault();

    const shareData = {
      url: this.data.get("urlValue"),
      text: this.textTarget.textContent,
      title: this.titleTarget.textContent,
    };

    try {
      await navigator.share(shareData);
    } catch (e) {
      console.log(e);
    }
  }
}
