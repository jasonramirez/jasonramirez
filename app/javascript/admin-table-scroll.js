function initializeTableOverlays() {
  const tableContainers = document.querySelectorAll(".table-container");

  tableContainers.forEach((container) => {
    // Skip if already initialized
    if (container.dataset.overlayInitialized) return;

    // Create the overflow cover element if it doesn't exist
    let overflowCover = container.querySelector(
      ".table-container__overflow-cover"
    );
    if (!overflowCover) {
      overflowCover = document.createElement("div");
      overflowCover.className = "table-container__overflow-cover";
      container.appendChild(overflowCover);
    }

    // Find the table wrapper for scroll detection
    const tableWrapper = container.querySelector(
      ".table-container__table-wrapper"
    );
    if (!tableWrapper) return;

    function updateGradient() {
      const isAtEnd =
        tableWrapper.scrollLeft + tableWrapper.clientWidth >=
        tableWrapper.scrollWidth - 1;

      if (isAtEnd) {
        container.classList.remove("has-more-content");
        container.classList.add("at-end");
      } else {
        container.classList.add("has-more-content");
        container.classList.remove("at-end");
      }
    }

    // Initial check
    updateGradient();

    // Update on scroll (on the table wrapper, not the container)
    tableWrapper.addEventListener("scroll", updateGradient);

    // Update on window resize
    window.addEventListener("resize", updateGradient);

    // Mark as initialized
    container.dataset.overlayInitialized = "true";
  });
}

// Run on DOM ready
document.addEventListener("DOMContentLoaded", initializeTableOverlays);

// Also run after a short delay to catch any late-loading content
setTimeout(initializeTableOverlays, 100);

// Run on Turbo navigation (if using Turbo)
if (typeof Turbo !== "undefined") {
  document.addEventListener("turbo:load", initializeTableOverlays);
  document.addEventListener("turbo:render", initializeTableOverlays);
}
