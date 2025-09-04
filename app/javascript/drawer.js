class Drawer {
  constructor(element) {
    this.drawer = element;
    this.triggerOpen = document.querySelector("[data-js-drawer-open-trigger]");
    this.triggerClose = document.querySelector(
      "[data-js-drawer-close-trigger]"
    );
    this.openClass = "open";

    this._bindEvents();
  }

  _bindEvents() {
    if (this.triggerOpen) {
      this.triggerOpen.addEventListener("click", this._openDrawer.bind(this));
    }
    if (this.triggerClose) {
      this.triggerClose.addEventListener("click", this._closeDrawer.bind(this));
    }
  }

  _openDrawer() {
    this.drawer.classList.toggle(this.openClass);
  }

  _closeDrawer() {
    this.drawer.classList.remove(this.openClass);
  }
}

export const initDrawers = () => {
  document.querySelectorAll("[data-js-drawer]").forEach((element) => {
    new Drawer(element);
  });
};
