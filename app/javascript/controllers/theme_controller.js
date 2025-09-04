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
      this.initializeTheme();

      // Listen for Turbo navigation events to reinitialize theme
      this.turboLoadHandler = () => {
        this.initializeTheme();
      };
      document.addEventListener("turbo:load", this.turboLoadHandler);
    }
  }

  disconnect() {
    // Clean up event listener
    if (this.turboLoadHandler) {
      document.removeEventListener("turbo:load", this.turboLoadHandler);
    }
  }

  initializeTheme() {
    // Get theme from localStorage or default to dark
    const savedTheme = localStorage.getItem("theme") || "dark";

    // Apply theme immediately without triggering setTheme (to avoid duplicate work)
    document.body.classList.remove("light", "dark");
    document.body.classList.add(savedTheme);
    document.documentElement.setAttribute("data-theme", savedTheme);

    // Update stylesheet
    this.updateStylesheet(savedTheme);

    // Update meta theme-color
    this.updateMetaThemeColor(savedTheme);
  }

  toggle() {
    const currentTheme = this.getCurrentTheme();
    const newTheme = currentTheme === "dark" ? "light" : "dark";
    this.setTheme(newTheme);
  }

  setTheme(theme) {
    // Update localStorage
    localStorage.setItem("theme", theme);

    // Update body class and document attribute
    document.body.classList.remove("light", "dark");
    document.body.classList.add(theme);
    document.documentElement.setAttribute("data-theme", theme);

    // Update stylesheet
    this.updateStylesheet(theme);

    // Update meta theme-color
    this.updateMetaThemeColor(theme);
  }

  getCurrentTheme() {
    return localStorage.getItem("theme") || "dark";
  }

  updateStylesheet(theme) {
    const darkStylesheet = document.querySelector(
      'link[href*="application_dark"]'
    );
    let lightStylesheet = document.querySelector(
      'link[href*="application_light"]'
    );

    if (theme === "dark") {
      // Ensure dark theme is active
      if (darkStylesheet) {
        darkStylesheet.disabled = false;
      }
      if (lightStylesheet) {
        lightStylesheet.disabled = true;
      }
    } else {
      // Load light stylesheet if not already loaded
      if (!lightStylesheet) {
        lightStylesheet = document.createElement("link");
        lightStylesheet.rel = "stylesheet";
        lightStylesheet.href = this.lightStylesheetValue;
        lightStylesheet.setAttribute("data-theme-stylesheet", "light");
        document.head.appendChild(lightStylesheet);
      }

      // Switch to light theme
      if (darkStylesheet) {
        darkStylesheet.disabled = true;
      }
      if (lightStylesheet) {
        lightStylesheet.disabled = false;
      }
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
}
