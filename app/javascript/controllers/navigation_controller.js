import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["header", "themeSwitcher"];

  connect() {
    // Ensure theme switcher starts in normal position
    this.showThemeSwitcherInNav();
    this.setupIntersectionObserver();
    this.setupScrollListener();
  }

  disconnect() {
    if (this.intersectionObserver) {
      this.intersectionObserver.disconnect();
    }
    if (this.scrollListener) {
      window.removeEventListener("scroll", this.scrollListener);
    }
  }

  setupIntersectionObserver() {
    // Use Intersection Observer to detect when header is visible
    this.intersectionObserver = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.showThemeSwitcherInNav();
          } else {
            this.hideThemeSwitcherInNav();
          }
        });
      },
      {
        threshold: 0.1, // Trigger when 10% of header is visible
      }
    );

    if (this.hasHeaderTarget) {
      this.intersectionObserver.observe(this.headerTarget);
    }
  }

  setupScrollListener() {
    // Fallback scroll listener for older browsers
    this.scrollListener = this.throttle(() => {
      const headerRect = this.headerTarget.getBoundingClientRect();
      const isHeaderVisible = headerRect.top >= -50; // 50px threshold

      if (isHeaderVisible) {
        this.showThemeSwitcherInNav();
      } else {
        this.hideThemeSwitcherInNav();
      }
    }, 100);

    window.addEventListener("scroll", this.scrollListener);
  }

  showThemeSwitcherInNav() {
    if (this.hasThemeSwitcherTarget) {
      this.themeSwitcherTarget.classList.remove("navigation__link--fixed");
    }
  }

  hideThemeSwitcherInNav() {
    if (this.hasThemeSwitcherTarget) {
      this.themeSwitcherTarget.classList.add("navigation__link--fixed");
    }
  }

  // Utility function to throttle scroll events
  throttle(func, limit) {
    let inThrottle;
    return function () {
      const args = arguments;
      const context = this;
      if (!inThrottle) {
        func.apply(context, args);
        inThrottle = true;
        setTimeout(() => (inThrottle = false), limit);
      }
    };
  }
}
