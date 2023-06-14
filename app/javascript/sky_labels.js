export default class SkyLabels {
  constructor() {
    this.skyLabelSelector = ".sky-label";
    this.hasTextClass = "sky-label-has-text";
    this.focusedClass = "sky-label-focused";

    this._bindEvents();

    setTimeout(() => this._hideLabelsIfInputHasText(), 150);
  }

  _bindEvents() {
    $(document)
      .on(
        "focus blur",
        this.skyLabelSelector,
        this._addOrRemoveHasTextClass.bind(this)
      )
      .on("focus", this.skyLabelSelector, this._addFocusedClass.bind(this))
      .on("blur", this.skyLabelSelector, this._removeFocusedClass.bind(this));
  }

  _addOrRemoveHasTextClass(event) {
    const fieldWrapper = $(event.currentTarget);

    if (this._fieldWrapperHasText(fieldWrapper)) {
      fieldWrapper.addClass(this.hasTextClass);
    } else {
      fieldWrapper.removeClass(this.hasTextClass);
    }
  }

  _fieldWrapperHasText(fieldWrapper) {
    const textField = fieldWrapper.find("input, textarea");

    return $.trim(textField.val()).length != 0;
  }

  _addFocusedClass(event) {
    $(event.currentTarget).addClass(this.focusedClass);
  }

  _removeFocusedClass(event) {
    $(event.currentTarget).removeClass(this.focusedClass);
  }

  _hideLabelsIfInputHasText() {
    $(this.skyLabelSelector).trigger("blur");
  }
}

new SkyLabels();
