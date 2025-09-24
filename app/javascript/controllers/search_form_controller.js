import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "clearButton"];

  connect() {
    console.log("Search form controller connected");
    this.toggleClearButton();
  }

  inputChanged() {
    this.toggleClearButton();
  }

  toggleClearButton() {
    if (this.inputTarget.value.trim().length > 0) {
      this.clearButtonTarget.style.display = "flex";
    } else {
      this.clearButtonTarget.style.display = "none";
    }
  }

  clearSearch() {
    this.inputTarget.value = "";
    this.toggleClearButton();

    // Use fetch with Turbo Stream to clear results without page refresh
    fetch(window.location.pathname, {
      method: "GET",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest",
      },
    })
      .then((response) => response.text())
      .then((html) => {
        // Parse and execute the turbo stream
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");
        const turboStreams = doc.querySelectorAll("turbo-stream");

        turboStreams.forEach((stream) => {
          const action = stream.getAttribute("action");
          const target = stream.getAttribute("target");
          const template = stream.querySelector("template");

          if (action === "replace" && target && template) {
            const targetElement = document.getElementById(target);
            if (targetElement) {
              targetElement.innerHTML = template.innerHTML;
            }
          }
        });
      })
      .catch((error) => {
        console.error("Clear search error:", error);
      });
  }

  submit(event) {
    event.preventDefault();
    console.log("Search form submitted");

    const searchTerm = this.inputTarget.value.trim();
    console.log("Search term:", searchTerm);

    // Build URL with search parameter
    const url = new URL(window.location.pathname, window.location.origin);
    if (searchTerm) {
      url.searchParams.set("search", searchTerm);
    }

    // Use fetch with Turbo Stream to update results without page refresh
    fetch(url.toString(), {
      method: "GET",
      headers: {
        Accept: "text/vnd.turbo-stream.html",
        "X-Requested-With": "XMLHttpRequest",
      },
    })
      .then((response) => response.text())
      .then((html) => {
        console.log("Received response:", html);
        // Parse and execute the turbo stream
        const parser = new DOMParser();
        const doc = parser.parseFromString(html, "text/html");
        const turboStreams = doc.querySelectorAll("turbo-stream");
        console.log("Found turbo streams:", turboStreams.length);

        turboStreams.forEach((stream) => {
          const action = stream.getAttribute("action");
          const target = stream.getAttribute("target");
          const template = stream.querySelector("template");
          console.log("Processing stream:", action, target);

          if (action === "replace" && target && template) {
            const targetElement = document.getElementById(target);
            if (targetElement) {
              console.log("Updating element:", target);
              targetElement.innerHTML = template.innerHTML;
            } else {
              console.log("Target element not found:", target);
            }
          }
        });
      })
      .catch((error) => {
        console.error("Search error:", error);
      });
  }
}
