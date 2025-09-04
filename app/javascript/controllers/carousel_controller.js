import { Controller } from "@hotwired/stimulus";
import { initCarousel } from "carousel";

export default class extends Controller {
  connect() {
    if (!this.element.dataset.carouselInitialized) {
      initCarousel(this.element);
      this.element.dataset.carouselInitialized = "true";
    }
  }
}
