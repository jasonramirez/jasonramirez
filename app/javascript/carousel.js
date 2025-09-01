import "hammerjs";

class Carousel {
  constructor(element) {
    this.element = element;
    this.currentCard = 1;
    this.firstCard = 1;
    this.lastCard = element.querySelectorAll("[data-js-carousel-card]").length;
    this.maxCardHeight = 0;
    this.totalImages = element.querySelectorAll("img").length;
    this.imagesLoaded = 0;

    // Cache DOM elements
    this.carouselCardsPlaceholder = element.querySelector(
      "[data-js-carousel-cards-placeholder]"
    );
    this.carouselCardsContainer = element.querySelector(
      "[data-js-carousel-cards]"
    );
    this.carouselActions = element.querySelector("[data-js-carousel-actions]");
    this.carouselCards = element.querySelectorAll("[data-js-carousel-card]");
    this.carouselIndex = element.querySelector("[data-js-carousel-index]");
    this.nextCardTrigger = element.querySelector("[data-js-carousel-next]");
    this.previousCardTrigger = element.querySelector(
      "[data-js-carousel-previous]"
    );

    // CSS classes
    this.carouselIndexSelectedClass = "carousel__index--selected";
    this.disabledClass = "disabled";

    this._bindEvents();
    this._setIndexContent();
    this._setIndexSelected();
    this._setTriggerState();
    this._setContainerSize();

    if (this.totalImages > 0) {
      this._loadImages();
    } else {
      this._onImageLoad();
    }
  }

  get atFirstCard() {
    return this.currentCard === this.firstCard;
  }

  get atLastCard() {
    return this.currentCard === this.lastCard;
  }

  get leftPosition() {
    return (this.currentCard - 1) * 100;
  }

  _bindEvents() {
    if (this.nextCardTrigger) {
      this.nextCardTrigger.addEventListener("click", this._nextCard.bind(this));
    }
    if (this.previousCardTrigger) {
      this.previousCardTrigger.addEventListener(
        "click",
        this._previousCard.bind(this)
      );
    }

    // Add Hammer.js touch/swipe support
    this._bindHammerEvents();

    window.addEventListener(
      "resize",
      this._debounce(() => {
        this._setContainerSize();
      }, 250)
    );
  }

  _bindHammerEvents() {
    if (typeof Hammer !== "undefined") {
      const hammer = new Hammer(this.element);

      // Configure recognizers
      hammer.get("swipe").set({ direction: Hammer.DIRECTION_HORIZONTAL });

      // Bind swipe events
      hammer.on("swipeleft", () => {
        if (!this.atLastCard) {
          this._nextCard();
        }
      });

      hammer.on("swiperight", () => {
        if (!this.atFirstCard) {
          this._previousCard();
        }
      });
    }
  }

  _loadImages() {
    const images = this.element.querySelectorAll("img");
    images.forEach((img) => {
      if (img.complete) {
        this._onImageLoad();
      } else {
        img.addEventListener("load", () => this._onImageLoad());
        img.addEventListener("error", () => this._onImageLoad()); // Continue even if image fails
      }
    });
  }

  _onImageLoad() {
    this.imagesLoaded++;
    if (this.imagesLoaded >= this.totalImages) {
      this._setContainerSize();
    }
  }

  _getMaxCardHeight() {
    const heightArray = Array.from(this.carouselCards).map((card) => {
      return card.offsetHeight;
    });
    return Math.max(...heightArray);
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
    if (this.carouselIndex) {
      for (let i = 0; i < this.lastCard; i++) {
        this.carouselIndex.appendChild(this._indexItem(i));
      }
    }
  }

  _indexItem(index) {
    const div = document.createElement("div");
    div.setAttribute("data-js-carousel-index-item", index);
    div.className = "carousel__index";
    return div;
  }

  _setIndexSelected() {
    if (this.carouselIndex) {
      // Remove selected class from all index items
      this.carouselIndex
        .querySelectorAll("." + this.carouselIndexSelectedClass)
        .forEach((item) => {
          item.classList.remove(this.carouselIndexSelectedClass);
        });

      // Add selected class to current index item
      const currentIndexItem = this.element.querySelector(
        `[data-js-carousel-index-item="${this.currentCard - 1}"]`
      );
      if (currentIndexItem) {
        currentIndexItem.classList.add(this.carouselIndexSelectedClass);
      }
    }
  }

  _setContainerSize() {
    this.maxCardHeight = this._getMaxCardHeight();
    if (this.carouselCardsPlaceholder) {
      this.carouselCardsPlaceholder.style.minHeight = `${this.maxCardHeight}px`;
    }
  }

  _setTriggerState() {
    if (this.carouselActions) {
      const links = this.carouselActions.querySelectorAll("a");
      if (this.atFirstCard) {
        if (links[0]) links[0].classList.add(this.disabledClass);
      } else if (this.atLastCard) {
        if (links[links.length - 1])
          links[links.length - 1].classList.add(this.disabledClass);
      } else {
        links.forEach((link) => link.classList.remove(this.disabledClass));
      }
    }
  }

  _setLeftPosition() {
    if (this.carouselCardsContainer) {
      this.carouselCardsContainer.style.left = `-${this.leftPosition}vw`;
    }
  }
}

const initCarousels = () => {
  document.querySelectorAll("[data-js-carousel]").forEach((element) => {
    if (!element.dataset.carouselInitialized) {
      try {
        new Carousel(element);
        element.dataset.carouselInitialized = "true";
      } catch (error) {
        console.error("Failed to initialize carousel:", error);
      }
    }
  });
};

// Initialize on turbo:load and DOM ready
document.addEventListener("turbo:load", initCarousels);
document.addEventListener("DOMContentLoaded", initCarousels);
