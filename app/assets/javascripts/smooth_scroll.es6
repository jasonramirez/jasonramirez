class SmoothScroll {
  get position() {
    const navHeight = $(".site-header").height();

    return $(this.target).offset().top - navHeight;
  }

  get target() {
    return $(this.element).attr("href");
  }

  constructor(element) {
    this.element = element;
    this._bindEvent(element);
  }

  _bindEvent(element) {
    $(element).on("click", this._scrollTo.bind(this));
  }

  _scrollTo() {
    event.preventDefault();

    $("html, body").animate({
      scrollTop: this.position
    }, 500);
  }
}

$("[data-smooth-scroll]").each(function() {
  new SmoothScroll(this);
})
