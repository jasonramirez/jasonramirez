import { Controller } from "@hotwired/stimulus";
import { initFlexibleTextareas } from "flexible-textarea";

export default class extends Controller {
  connect() {
    initFlexibleTextareas();
  }
}
