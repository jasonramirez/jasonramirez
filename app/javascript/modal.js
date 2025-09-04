class Modal {
  constructor() {
    console.log("Modal class initialized");
    this.originalParent = null;
    this.bindEvents();
  }

  bindEvents() {
    this.bindModalOpenEvents();
    this.bindModalCloseEvents();
    this.bindFormSubmissionEvents();
    this.bindDynamicConfirmEvents();
    this.bindKeyboardEvents();
  }

  bindModalOpenEvents() {
    document.addEventListener("click", (e) => {
      // Find the closest element with data-modal attribute (handles clicks on child elements)
      const modalTrigger = e.target.closest("[data-modal]");

      if (modalTrigger) {
        console.log("Found modal trigger:", modalTrigger);
        e.preventDefault();
        const modalId = modalTrigger.dataset.modal;
        if (modalId) {
          const modalData = modalTrigger.dataset;
          this.open(modalId, modalData);
        }
      }
    });
  }

  bindModalCloseEvents() {
    document.addEventListener("click", (e) => {
      if (e.target.matches("[data-modal-close]")) {
        e.preventDefault();
        this.handleModalClose(e.target);
      }
    });
  }

  bindFormSubmissionEvents() {
    document.addEventListener("submit", (e) => {
      const submitButton = e.target.querySelector("[data-modal-close]");
      if (submitButton) {
        this.closeModalById(submitButton.dataset.modalClose);
      }
    });
  }

  bindDynamicConfirmEvents() {
    document.addEventListener("click", (e) => {
      if (e.target.id === "modal-confirm-button") {
        const modal = e.target.closest("[data-modal-overlay]");
        if (modal && modal.modalData) {
          this.handleDynamicConfirm(modal);
        }
      }
    });
  }

  bindKeyboardEvents() {
    document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        this.closeOpenModal();
      }
    });
  }

  open(modalId, modalData = null) {
    const modal = document.getElementById(modalId);
    if (modal) {
      this.storeModalData(modal, modalData);
      this.moveModalToBody(modal);
      this.bindCloseEvents(modal);
      this.populateDynamicContent(modal);
      this.showModal(modal);
    }
  }

  storeModalData(modal, modalData) {
    if (modalData) {
      modal.modalData = modalData;
    }
  }

  moveModalToBody(modal) {
    this.originalParent = modal.parentElement;
    if (modal.parentElement !== document.body) {
      document.body.appendChild(modal);
    }
  }

  showModal(modal) {
    modal.classList.add("modal--open");
    document.body.style.overflow = "hidden";
  }

  bindCloseEvents(modal) {
    this.bindCloseButtonEvents(modal);
    this.bindOverlayClickEvents(modal);
  }

  bindCloseButtonEvents(modal) {
    const closeButton = modal.querySelector("[data-modal-close]");
    if (closeButton) {
      closeButton.addEventListener("click", (e) => {
        e.preventDefault();
        this.close(modal);
      });
    }
  }

  bindOverlayClickEvents(modal) {
    modal.addEventListener("click", (e) => {
      if (e.target === modal) {
        this.close(modal);
      }
    });
  }

  populateDynamicContent(modal) {
    if (modal.modalData) {
      this.populateHashtagLabel(modal);
    }
  }

  populateHashtagLabel(modal) {
    const labelSpan = modal.querySelector("#hashtag-label");
    if (labelSpan && modal.modalData.hashtagLabel) {
      labelSpan.textContent = modal.modalData.hashtagLabel;
    }
  }

  handleModalClose(closeButton) {
    const modalId = closeButton.dataset.modalClose;
    if (modalId) {
      this.closeModalById(modalId);
    } else {
      this.closeClosestModal(closeButton);
    }
  }

  closeModalById(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) {
      this.close(modal);
    }
  }

  closeClosestModal(element) {
    const modal = element.closest("[data-modal-overlay]");
    if (modal) {
      this.close(modal);
    }
  }

  closeOpenModal() {
    const openModal = document.querySelector(
      "[data-modal-overlay].modal--open"
    );
    if (openModal) {
      this.close(openModal);
    }
  }

  close(modal) {
    if (modal) {
      this.hideModal(modal);
      this.restoreModalPosition(modal);
    }
  }

  hideModal(modal) {
    modal.classList.remove("modal--open");
  }

  restoreModalPosition(modal) {
    if (this.originalParent) {
      this.originalParent.appendChild(modal);
    }
  }

  handleDynamicConfirm(modal) {
    if (modal.modalData && modal.modalData.deleteUrl) {
      this.submitDeleteForm(modal);
      this.close(modal);
    }
  }

  submitDeleteForm(modal) {
    const form = this.createDeleteForm(modal.modalData.deleteUrl);
    this.addReplacementHashtag(form, modal);
    this.submitForm(form);
  }

  createDeleteForm(deleteUrl) {
    const form = document.createElement("form");
    form.method = "POST";
    form.action = deleteUrl;

    this.addMethodOverride(form);
    this.addCsrfToken(form);

    return form;
  }

  addMethodOverride(form) {
    const methodInput = document.createElement("input");
    methodInput.type = "hidden";
    methodInput.name = "_method";
    methodInput.value = "DELETE";
    form.appendChild(methodInput);
  }

  addCsrfToken(form) {
    const csrfToken = this.getCsrfToken();
    if (csrfToken) {
      const csrfInput = document.createElement("input");
      csrfInput.type = "hidden";
      csrfInput.name = "authenticity_token";
      csrfInput.value = csrfToken;
      form.appendChild(csrfInput);
    }
  }

  addReplacementHashtag(form, modal) {
    const replacementSelect = modal.querySelector("#replacement-hashtag");
    if (replacementSelect && replacementSelect.value) {
      const replacementInput = document.createElement("input");
      replacementInput.type = "hidden";
      replacementInput.name = "replacement_hashtag_id";
      replacementInput.value = replacementSelect.value;
      form.appendChild(replacementInput);
    }
  }

  getCsrfToken() {
    return document
      .querySelector('meta[name="csrf-token"]')
      ?.getAttribute("content");
  }

  submitForm(form) {
    document.body.appendChild(form);
    form.submit();
  }
}

// Initialize modal functionality
document.addEventListener("DOMContentLoaded", () => {
  new Modal();
});

// Make Modal class globally available
window.Modal = Modal;
