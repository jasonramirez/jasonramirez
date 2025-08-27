import "hammerjs";

export default class Carousel {
  constructor(element) {
    this.carouselIndexSelectedClass = "carousel__index--selected";
    this.currentCard = 1;
    this.disabledClass = "button--disabled";
    this.firstCard = 1;
    this.hammer = new Hammer(element);
    this.lastCard = $(element).find("[data-js-carousel-card]").length;
    this.imagesLoaded = 0;
    this.totalImages = $(element).find("img").length;

    this.$element = $(element);
    this.$window = $(window);
    this.$carouselCardsPlaceholder = $(element).find(
      "[data-js-carousel-cards-placeholder]"
    );
    this.$carouselCardsContainer = $(element).find("[data-js-carousel-cards]");
    this.$carouselActions = $(element).find("[data-js-carousel-actions]");
    this.$carouselCards = $(element).find("[data-js-carousel-card]");
    this.$carouselIndex = $(element).find("[data-js-carousel-index]");
    this.$nextCardTrigger = $(element).find(
      "[data-js-carousel-next-card-trigger]"
    );
    this.$previousCardTrigger = $(element).find(
      "[data-js-carousel-previous-card-trigger]"
    );

    this._waitForImages();
  }

  _waitForImages() {
    if (this.totalImages === 0) {
      this._initialize();
      return;
    }

    this.$element.find("img").each((index, img) => {
      const $img = $(img);

      if (img.complete) {
        this._onImageLoad();
      } else {
        $img.on("load", () => this._onImageLoad());
        $img.on("error", () => this._onImageLoad()); // Continue even if image fails
      }
    });
  }

  _onImageLoad() {
    this.imagesLoaded++;
    if (this.imagesLoaded >= this.totalImages) {
      this._initialize();
    }
  }

  _initialize() {
    this._setTriggerState();
    this._setContainerSize();
    this._setIndexContent();
    this._setIndexSelected();
    this._bindEvents();

    // Add a small delay to ensure DOM is ready
    setTimeout(() => {
      this._setLeftPosition();
    }, 50);
  }

  get leftPosition() {
    return (this.currentCard - 1) * 100;
  }

  get atLastCard() {
    return this.currentCard >= this.lastCard;
  }

  get atFirstCard() {
    return this.currentCard <= this.firstCard;
  }

  get maxCardHeight() {
    const heightArray = this.$element
      .find("[data-js-carousel-card]")
      .map(function () {
        return $(this).height();
      })
      .get();

    return Math.max(...heightArray) || 400; // Fallback height
  }

  _bindEvents() {
    this.hammer.on("swipeleft", this._nextCard.bind(this));
    this.hammer.on("swiperight", this._previousCard.bind(this));
    this.$nextCardTrigger.on("click", this._nextCard.bind(this));
    this.$previousCardTrigger.on("click", this._previousCard.bind(this));
    this.$window.on(
      "resize",
      this._debounce(this._setContainerSize.bind(this), 250)
    );
  }

  _debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  }

  _increaseCount() {
    if (this.atLastCard) {
      this.currentCard = this.firstCard;
    } else {
      this.currentCard++;
    }
  }

  _decreaseCount() {
    if (this.atFirstCard) {
      this.currentCard = this.lastCard;
    } else {
      this.currentCard--;
    }
  }

  _nextCard(event) {
    if (event) event.preventDefault();
    this._increaseCount();
    this._setIndexSelected();
    this._setTriggerState();
    this._setLeftPosition();
  }

  _previousCard(event) {
    if (event) event.preventDefault();
    this._decreaseCount();
    this._setIndexSelected();
    this._setTriggerState();
    this._setLeftPosition();
  }

  _setIndexContent() {
    for (let i = 0; i < this.lastCard; i++) {
      this.$carouselIndex.append(this._indexItem(i));
    }
  }

  _indexItem(index) {
    return `<div data-js-carousel-index-item="${index}"
      class="carousel__index"></div>`;
  }

  _setIndexSelected() {
    this.$carouselIndex.children().removeClass(this.carouselIndexSelectedClass);

    this.$element
      .find(`[data-js-carousel-index-item="${this.currentCard - 1}"]`)
      .addClass(this.carouselIndexSelectedClass);
  }

  _setContainerSize() {
    const height = this.maxCardHeight;
    this.$carouselCardsPlaceholder.css("min-height", `${height}px`);
  }

  _setTriggerState() {
    if (this.atFirstCard) {
      this.$carouselActions.find("a:first-child").addClass(this.disabledClass);
    } else if (this.atLastCard) {
      this.$carouselActions.find("a:last-child").addClass(this.disabledClass);
    } else {
      this.$carouselActions.find("a").removeClass(this.disabledClass);
    }
  }

  _setLeftPosition() {
    this.$carouselCardsContainer.css("left", `-${this.leftPosition}vw`);
  }
}

const initCarousels = () => {
  $("[data-js-carousel]").each((index, element) => {
    if (!$(element).data("carousel-initialized")) {
      try {
        new Carousel(element);
        $(element).data("carousel-initialized", true);
      } catch (error) {
        console.error("Failed to initialize carousel:", error);
      }
    }
  });
};

$(document).on("turbo:load", initCarousels).ready(initCarousels);
