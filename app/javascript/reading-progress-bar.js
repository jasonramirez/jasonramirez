class ReadingProgressBar {
  constructor(element) {
    this.progressBar = element;

    this._bindEvents();
  }

  _bindEvents() {
    document.addEventListener("scroll", this._setProgressBar.bind(this));
  }

  _setProgressBar() {
    let scrollDist = window.pageYOffset || document.documentElement.scrollTop;

    let progressWidth =
      (scrollDist /
        (document.documentElement.scrollHeight - window.innerHeight)) *
      100;

    this.progressBar.style.width = progressWidth + "%";
  }
}

const initReadingProgressBars = () => {
  document
    .querySelectorAll("[data-js-reading-progress-bar]")
    .forEach((element) => {
      new ReadingProgressBar(element);
    });
};

// Initialize on turbo:load and DOM ready
document.addEventListener("turbo:load", initReadingProgressBars);
document.addEventListener("DOMContentLoaded", initReadingProgressBars);
