class FlexibleTextarea {
  constructor(element) {
    this.element = element;

    this._bindEvents();
    this._resize();
  }

  get _newTextAreaHeight() {
    return `${this.element.scrollHeight + 16}px`;
  }

  _bindEvents() {
    this.element.addEventListener("input", this._resize.bind(this));
  }

  _resize() {
    this.element.style.height = "auto";
    this.element.style.height = this._newTextAreaHeight;
  }
}

const initFlexibleTextareas = () => {
  document
    .querySelectorAll("[data-js-flexible-textarea]")
    .forEach((element) => {
      new FlexibleTextarea(element);
    });
};

// Initialize on turbo:load and DOM ready
document.addEventListener("turbo:load", initFlexibleTextareas);
document.addEventListener("DOMContentLoaded", initFlexibleTextareas);
