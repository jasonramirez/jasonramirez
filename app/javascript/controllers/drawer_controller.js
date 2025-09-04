import { Controller } from "@hotwired/stimulus";
import { initDrawers } from "drawer";

export default class extends Controller {
  connect() {
    initDrawers();
  }
}
