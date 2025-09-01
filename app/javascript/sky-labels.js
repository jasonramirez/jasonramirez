class SkyLabels {
  constructor() {
    this.skyLabelSelector = ".sky-label";
    this.hasTextClass = "sky-label-has-text";
    this.focusedClass = "sky-label-focused";

    this._bindEvents();

    setTimeout(() => this._hideLabelsIfInputHasText(), 150);
  }

  _bindEvents() {
    document.addEventListener(
      "focus",
      (event) => {
        if (event.target.matches(this.skyLabelSelector)) {
          this._addOrRemoveHasTextClass(event);
          this._addFocusedClass(event);
        }
      },
      true
    );

    document.addEventListener(
      "blur",
      (event) => {
        if (event.target.matches(this.skyLabelSelector)) {
          this._addOrRemoveHasTextClass(event);
          this._removeFocusedClass(event);
        }
      },
      true
    );
  }

  _addOrRemoveHasTextClass(event) {
    const fieldWrapper = event.currentTarget;

    if (this._fieldWrapperHasText(fieldWrapper)) {
      fieldWrapper.classList.add(this.hasTextClass);
    } else {
      fieldWrapper.classList.remove(this.hasTextClass);
    }
  }

  _fieldWrapperHasText(fieldWrapper) {
    const textField = fieldWrapper.querySelector("input, textarea");

    return textField.value.trim().length !== 0;
  }

  _addFocusedClass(event) {
    event.currentTarget.classList.add(this.focusedClass);
  }

  _removeFocusedClass(event) {
    event.currentTarget.classList.remove(this.focusedClass);
  }

  _hideLabelsIfInputHasText() {
    const labels = document.querySelectorAll(this.skyLabelSelector);
    labels.forEach((label) => {
      const event = new Event("blur", { bubbles: true });
      label.dispatchEvent(event);
    });
  }
}

const initSkyLabels = () => {
  new SkyLabels();
};

// Initialize on turbo:load and DOM ready
document.addEventListener("turbo:load", initSkyLabels);
document.addEventListener("DOMContentLoaded", initSkyLabels);
