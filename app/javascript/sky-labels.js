class SkyLabels {
  constructor() {
    this.skyLabelSelector = ".sky-label";
    this.hasTextClass = "sky-label-has-text";
    this.focusedClass = "sky-label-focused";

    this._bindEvents();
    setTimeout(() => this._initializeLabels(), 150);
  }

  _bindEvents() {
    document.addEventListener("focus", this._handleFocus.bind(this), true);
    document.addEventListener("blur", this._handleBlur.bind(this), true);
    document.addEventListener("input", this._handleInput.bind(this), true);
  }

  _handleFocus(event) {
    const wrapper = event.target.closest(this.skyLabelSelector);
    if (wrapper) {
      this._updateClasses(wrapper, true);
    }
  }

  _handleBlur(event) {
    const wrapper = event.target.closest(this.skyLabelSelector);
    if (wrapper) {
      this._updateClasses(wrapper, false);
    }
  }

  _handleInput(event) {
    const wrapper = event.target.closest(this.skyLabelSelector);
    if (wrapper) {
      this._updateClasses(
        wrapper,
        wrapper.classList.contains(this.focusedClass)
      );
    }
  }

  _updateClasses(wrapper, isFocused) {
    if (!wrapper) return;

    const input = wrapper.querySelector("input, textarea");
    if (!input) return;

    const hasText = input.value.trim().length > 0;

    wrapper.classList.toggle(this.hasTextClass, hasText);
    wrapper.classList.toggle(this.focusedClass, isFocused);
  }

  _initializeLabels() {
    document.querySelectorAll(this.skyLabelSelector).forEach((label) => {
      const input = label.querySelector("input, textarea");
      if (input && input.value.trim().length > 0) {
        label.classList.add(this.hasTextClass);
      }
    });
  }

  // Force re-initialization for dynamically loaded content
  reinitialize() {
    this._initializeLabels();
  }
}

const initSkyLabels = () => {
  window.skyLabelsInstance = new SkyLabels();
};

document.addEventListener("turbo:load", initSkyLabels);
document.addEventListener("DOMContentLoaded", initSkyLabels);
document.addEventListener("turbo:frame-load", () => {
  // Reinitialize sky-labels when Turbo frames load
  if (window.skyLabelsInstance) {
    window.skyLabelsInstance.reinitialize();
  }
});

// Reinitialize sky-labels on DOMContentLoaded for pre-filled forms
document.addEventListener("DOMContentLoaded", function () {
  if (window.skyLabelsInstance) {
    window.skyLabelsInstance.reinitialize();
  }
});
