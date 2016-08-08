class FlexibleTextarea {
  constructor(element) {
    this.$element = $("[data-flexible-textarea]");
    this._bindEvents()
  }

  _bindEvents() {
    this.$element.flexible()
    this.$element.on("keyup", "updateHeight")
  }
}

new FlexibleTextarea();
