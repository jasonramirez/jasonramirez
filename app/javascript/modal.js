class Modal {
  constructor() {
    this.originalParent = null;
    this.bindEvents();
  }

  bindEvents() {
    document.addEventListener("click", (e) => {
      if (e.target.matches("[data-modal-trigger]")) {
        const modalId = e.target.dataset.modalId;
        if (modalId) {
          this.open(modalId);
        }
      }
    });

    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        const openModal = document.querySelector(
          "[data-modal-overlay].modal--open"
        );
        if (openModal) {
          this.close(openModal);
        }
      }
    });
  }

  open(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      this.originalParent = modal.parentElement;

      if (modal.parentElement !== document.body) {
        document.body.appendChild(modal);
      }

      this.bindCloseEvents(modal);

      modal.classList.add("modal--open");
      document.body.style.overflow = "hidden";
    }
  }

  bindCloseEvents(modal) {
    const closeButton = modal.querySelector("[data-modal-close]");
    if (closeButton) {
      closeButton.addEventListener("click", (e) => {
        e.preventDefault();
        this.close(modal);
      });
    }

    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        this.close(modal);
      }
    });
  }

  close(modal) {
    if (modal) {
      modal.classList.remove("modal--open");
      //document.body.style.overflow = "";

      // Move modal back to its original location
      if (this.originalParent) {
        this.originalParent.appendChild(modal);
      }
    }
  }
}

// Initialize modal functionality
document.addEventListener("DOMContentLoaded", () => {
  new Modal();
});

// Make Modal class globally available
window.Modal = Modal;
