export default class Drawer {
  constructor(element) {
    this.$drawer = $(element);
    this.$triggerOpen = $("[data-js-drawer-open-trigger");
    this.$triggerClose = $("[data-js-drawer-close-trigger");
    this.openClass = "open";

    this._bindEvents();
  }

  _bindEvents() {
    this.$triggerOpen.on("click", this._openDrawer.bind(this));
    this.$triggerClose.on("click", this._closeDrawer.bind(this));
  }

  _openDrawer() {
    this.$drawer.toggleClass(this.openClass);
  }

  _closeDrawer() {
    this.$drawer.removeClass(this.openClass);
  }
}

$(document).on("turbo:load", () => {
  $("[data-js-drawer]").each((index, element) => new Drawer(element));
});
