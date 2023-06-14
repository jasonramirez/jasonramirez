export default class FlexibleTextarea {
  constructor(element) {
    this.$element = element;
    this._bindEvents();
  }

  _bindEvents() {
    this.$element.oninput = this._resize();
  }

  _resize() {
    this.$element.style.height = "5px";
    this.$element.style.height = element.scrollHeight + "px";
  }
}

$(document).on("turbolinks:load", function() {
  $("[data-js-flexible-textarea]").each(
    (index, element) => new FlexibleTextarea(element)
  );
});
