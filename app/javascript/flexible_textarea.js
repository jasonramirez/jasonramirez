export default class FlexibleTextarea {
  constructor(element) {
    this.$element = $(element);

    this._bindEvents();
    this._resize();
  }

  get _newTextAreaHeight() {
    return `${this.$element.prop("scrollHeight")}px`;
  }

  _bindEvents() {
    this.$element.on("input", this._resize.bind(this));
  }

  _resize() {
    this.$element.css("height", "auto").css("height", this._newTextAreaHeight);
  }
}

$(window).on("load", () => {
  $("[data-js-flexible-textarea]").each(
    (index, element) => new FlexibleTextarea(element)
  );
});
