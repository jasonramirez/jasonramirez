export default class ReadingProgressBar {
  constructor(element) {
    this.$progressBar = $(element);

    this._bindEvents();
  }

  _bindEvents() {
    $("body").scroll(this._setProgressBar.bind(this));
  }

  _setProgressBar() {
    let scrollDist = document.body.scrollTop;

    let progressWidth =
      (scrollDist /
        (document.body.scrollHeight - document.documentElement.clientHeight)) *
      100;

    this.$progressBar.css("width", progressWidth + "%");
  }
}

$(window).on("load", () => {
  $("[data-js-reading-progress-bar]").each(
    (index, element) => new ReadingProgressBar(element)
  );
});
