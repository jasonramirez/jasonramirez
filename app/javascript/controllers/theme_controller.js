import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["stylesheet"];
  static values = {
    lightStylesheet: String,
    darkStylesheet: String,
  };

  connect() {
    this.initializeTheme();
  }

  initializeTheme() {
    // Get theme from localStorage or default to dark
    const savedTheme = localStorage.getItem("theme") || "dark";
    this.setTheme(savedTheme);
  }

  toggle() {
    const currentTheme = this.getCurrentTheme();
    const newTheme = currentTheme === "dark" ? "light" : "dark";
    this.setTheme(newTheme);
  }

  setTheme(theme) {
    // Update localStorage
    localStorage.setItem("theme", theme);

    // Update body class
    document.body.className = document.body.className.replace(
      /light|dark/g,
      theme
    );

    // Update stylesheet
    this.updateStylesheet(theme);

    // Update meta theme-color
    this.updateMetaThemeColor(theme);
  }

  getCurrentTheme() {
    return localStorage.getItem("theme") || "dark";
  }

  updateStylesheet(theme) {
    // Enable/disable stylesheets based on theme
    const darkStylesheet = document.querySelector(
      'link[href*="application_dark"]'
    );
    const lightStylesheet = document.querySelector(
      'link[href*="application_light"]'
    );

    if (darkStylesheet && lightStylesheet) {
      if (theme === "dark") {
        darkStylesheet.disabled = false;
        lightStylesheet.disabled = true;
      } else {
        darkStylesheet.disabled = true;
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
