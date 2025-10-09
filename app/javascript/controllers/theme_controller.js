import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["stylesheet"];
  static values = {
    lightStylesheet: String,
    darkStylesheet: String,
  };

  connect() {
    // Only initialize if this is the body controller (not the button controller)
    if (this.element === document.body) {
      this.ensureThemeConsistency();

      // Listen for Turbo navigation events to ensure theme consistency
      this.turboLoadHandler = () => {
        // Use a small delay to ensure DOM is ready
        requestAnimationFrame(() => {
          this.ensureThemeConsistency();
        });
      };

      // Listen to multiple Turbo events for better coverage
      document.addEventListener("turbo:load", this.turboLoadHandler);
      document.addEventListener("turbo:render", this.turboLoadHandler);
    }
  }

  disconnect() {
    // Clean up event listeners
    if (this.turboLoadHandler) {
      document.removeEventListener("turbo:load", this.turboLoadHandler);
      document.removeEventListener("turbo:render", this.turboLoadHandler);
    }
  }

  ensureThemeConsistency() {
    try {
      // Get theme from localStorage or default to dark
      const savedTheme = localStorage.getItem("theme") || "dark";
      const currentBodyTheme = document.body.classList.contains("light")
        ? "light"
        : "dark";
      const currentDataTheme =
        document.documentElement.getAttribute("data-theme");

      // Only update if there's an inconsistency
      if (currentBodyTheme !== savedTheme || currentDataTheme !== savedTheme) {
        this.applyTheme(savedTheme);
      }
    } catch (error) {
      console.error("Theme consistency check failed:", error);
      // Fallback: apply dark theme
      this.applyTheme("dark");
    }
  }

  applyTheme(theme) {
    // Update body class and document attribute
    document.body.classList.remove("light", "dark");
    document.body.classList.add(theme);
    document.documentElement.setAttribute("data-theme", theme);

    // Update stylesheet
    this.updateStylesheet(theme);

    // Update meta theme-color
    this.updateMetaThemeColor(theme);

    // Update favicons
    this.updateFavicons(theme);
  }

  toggle() {
    try {
      const currentTheme = this.getCurrentTheme();
      const newTheme = currentTheme === "dark" ? "light" : "dark";
      this.setTheme(newTheme);
    } catch (error) {
      console.error("Theme toggle failed:", error);
      // Fallback: try to apply dark theme
      this.setTheme("dark");
    }
  }

  setTheme(theme) {
    // Update localStorage
    localStorage.setItem("theme", theme);

    // Apply the theme
    this.applyTheme(theme);
  }

  getCurrentTheme() {
    return localStorage.getItem("theme") || "dark";
  }

  updateStylesheet(theme) {
    // Find existing stylesheets by ID and data attributes
    const currentStylesheet = document.getElementById(
      `theme-stylesheet-${theme}`
    );
    const otherTheme = theme === "dark" ? "light" : "dark";
    const otherStylesheet = document.getElementById(
      `theme-stylesheet-${otherTheme}`
    );

    // Disable the other theme's stylesheet
    if (otherStylesheet) {
      otherStylesheet.disabled = true;
    }

    // Enable or create the current theme's stylesheet
    if (currentStylesheet) {
      currentStylesheet.disabled = false;
    } else {
      // Create new stylesheet for the theme
      const link = document.createElement("link");
      link.id = `theme-stylesheet-${theme}`;
      link.rel = "stylesheet";
      link.href =
        theme === "light"
          ? this.lightStylesheetValue
          : this.darkStylesheetValue;
      link.setAttribute("data-theme-stylesheet", theme);
      link.setAttribute("data-turbo-track", "reload");
      document.head.appendChild(link);
    }
  }

  updateMetaThemeColor(theme) {
    const themeColor = theme === "dark" ? "#181923" : "#fffaed";
    let metaThemeColor = document.querySelector('meta[name="theme-color"]');

    if (metaThemeColor) {
      metaThemeColor.content = themeColor;
    } else {
      metaThemeColor = document.createElement("meta");
      metaThemeColor.name = "theme-color";
      metaThemeColor.content = themeColor;
      document.head.appendChild(metaThemeColor);
    }
  }

  updateFavicons(theme) {
    const faviconLinks = document.querySelectorAll('link[rel*="icon"]');
    faviconLinks.forEach((link) => {
      const darkHref = link.getAttribute("data-dark-href");
      const lightHref = link.getAttribute("data-light-href");
      if (darkHref && lightHref) {
        link.setAttribute("href", theme === "light" ? lightHref : darkHref);
      }
    });

    const msTileImage = document.querySelector(
      'meta[name="msapplication-TileImage"]'
    );
    if (msTileImage) {
      const darkHref = msTileImage.getAttribute("data-dark-href");
      const lightHref = msTileImage.getAttribute("data-light-href");
      if (darkHref && lightHref) {
        msTileImage.setAttribute(
          "content",
          theme === "light" ? lightHref : darkHref
        );
      }
    }
  }
}
