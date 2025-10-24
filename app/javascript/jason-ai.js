class JasonAiChat {
  constructor() {
    this.form = null;
    this.submitButton = null;
    this.input = null;
    this.chatHistory = null;
    this.scrollToBottomButton = null;
    this.scrollContainer = null;
    this.init();
  }

  init() {
    // Check if DOM is already loaded
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", () => this.setup());
    } else {
      this.setup();
    }
  }

  setup() {
    this.form = document.querySelector("[data-jason-ai-chat='true']");

    // Only proceed if the form exists (we're on the jason-ai page)
    if (!this.form) {
      console.log("JasonAiChat: Form not found, exiting setup");
      return;
    }

    this.submitButton = this.form.querySelector(
      "[data-jason-ai-chat-button='true']"
    );
    this.input = this.form.querySelector("input[name='question']");
    this.chatHistory = document.querySelector(".jason-ai-chat-history");
    this.scrollToBottomButton = document.querySelector(
      "[data-scroll-to-bottom='true']"
    );
    this.scrollContainer = document.querySelector(
      "[data-jason-ai-chat-container='true']"
    );

    // Validate all required elements exist
    if (!this.submitButton || !this.input || !this.chatHistory) {
      console.error("JasonAiChat: Required elements not found:", {
        submitButton: !!this.submitButton,
        input: !!this.input,
        chatHistory: !!this.chatHistory,
      });
      return;
    }

    this.bindEvents();
    this.bindFeedbackEvents();
    this.bindScrollEvents();
    this.scrollToBottom();
    this.scrollToLatestMessage();

    console.log("JasonAiChat: Setup completed successfully");
  }

  bindEvents() {
    // Add click event listeners to existing ellipsis elements
    document.addEventListener("click", (e) => this.handleEllipsisClick(e));

    // Add click event listeners for copy buttons
    document.addEventListener("click", (e) => this.handleCopyClick(e));

    // Add form submit handler
    this.form.addEventListener("submit", (e) => this.handleSubmit(e));
    console.log("JasonAiChat: Form submit event listener attached");

    // Add Enter key handler for the input field
    if (this.input) {
      this.input.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault();

          // Check if we're already loading before submitting
          if (!this.submitButton.disabled) {
            this.form.dispatchEvent(new Event("submit"));
          }
        }
      });
    }

    // Add scroll-to-bottom button click handler
    if (this.scrollToBottomButton) {
      this.scrollToBottomButton.addEventListener("click", () => {
        this.scrollToBottom(true);
        this.hideScrollToBottomButton();
      });
    }
  }

  bindScrollEvents() {
    if (this.scrollContainer) {
      this.scrollContainer.addEventListener("scroll", () => {
        this.handleScroll();
      });
    }
  }

  handleScroll() {
    if (!this.scrollContainer) return;

    const isNearBottom =
      this.scrollContainer.scrollTop + this.scrollContainer.clientHeight >=
      this.scrollContainer.scrollHeight - 100;

    if (isNearBottom) {
      this.hideScrollToBottomButton();
    } else {
      this.showScrollToBottomButton();
    }
  }

  showScrollToBottomButton() {
    if (this.scrollToBottomButton) {
      this.scrollToBottomButton.style.display = "flex";
    }
  }

  hideScrollToBottomButton() {
    if (this.scrollToBottomButton) {
      this.scrollToBottomButton.style.display = "none";
    }
  }

  scrollToLatestMessage() {
    if (!this.scrollContainer) {
      console.log(
        "JasonAiChat: Scroll container not found for latest message scroll"
      );
      return;
    }

    // Find the most recent chat message
    const chatMessages = this.chatHistory.querySelectorAll(
      ".jason-ai-chat-message"
    );
    if (chatMessages.length === 0) {
      console.log("JasonAiChat: No chat messages found");
      return;
    }

    const latestMessage = chatMessages[chatMessages.length - 1];

    // Scroll to the very bottom of the container immediately (no animation)
    this.scrollContainer.scrollTo({
      top:
        this.scrollContainer.scrollHeight - this.scrollContainer.clientHeight,
      behavior: "instant",
    });

    console.log("JasonAiChat: Scrolled to latest message on page load");
  }

  handleEllipsisClick(e) {
    if (e.target.closest(".jason-ai-chat-message__more")) {
      const more = e.target.closest(".jason-ai-chat-message__more");
      const timestamp = more.getAttribute("data-timestamp");
      if (timestamp) {
        alert(timestamp);
      }
    }
  }

  handleCopyClick(e) {
    if (e.target.closest(".jason-ai-chat-message__copy")) {
      const copyButton = e.target.closest(".jason-ai-chat-message__copy");
      const messageElement = copyButton.closest(".jason-ai-chat-message");
      const contentElement = messageElement.querySelector(
        ".chat-message__content"
      );

      if (contentElement) {
        const textToCopy = contentElement.textContent.trim();

        // Copy to clipboard
        navigator.clipboard
          .writeText(textToCopy)
          .then(() => {
            // Show flash message
            this.showFlashMessage("Copied to clipboard");
          })
          .catch((err) => {
            this.showFlashMessage("Failed to copy to clipboard");
          });
      }
    }
  }

  async handleSubmit(e) {
    console.log("JasonAiChat: Form submit event triggered");
    e.preventDefault();
    e.stopPropagation();

    // Check if button is disabled to prevent multiple submissions
    if (this.submitButton.disabled) {
      console.log(
        "JasonAiChat: Submit button is disabled, ignoring submission"
      );
      return;
    }

    const question = this.input.value.trim();
    if (!question) {
      return;
    }

    // Add user's question to chat immediately
    await this.addUserQuestionToChat(question);

    this.setLoadingState(true);
    this.submitQuestion(question);
  }

  setLoadingState(loading) {
    this.submitButton.disabled = loading;
    this.input.disabled = loading;

    if (loading) {
      this.submitButton.classList.add("button--loading");
      // Store original content and show loading state
      if (!this.originalButtonContent) {
        this.originalButtonContent = this.submitButton.innerHTML;
      }
      this.submitButton.innerHTML = `
        <svg height="20" width="20" viewBox="0 0 24 24" fill="none" class="loading-spinner">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" opacity="0.3"/>
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2" fill="none" stroke-linecap="round" stroke-dasharray="60" stroke-dashoffset="60">
            <animateTransform attributeName="transform" type="rotate" dur="1s" repeatCount="indefinite" values="0 12 12;360 12 12"/>
          </circle>
        </svg>
      `;
    } else {
      this.submitButton.classList.remove("button--loading");
      // Restore original content
      if (this.originalButtonContent) {
        this.submitButton.innerHTML = this.originalButtonContent;
      }
      this.input.focus();
    }
  }

  async submitQuestion(question) {
    try {
      const response = await fetch(this.form.action, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: new URLSearchParams({
          question: question,
          authenticity_token: document.querySelector('meta[name="csrf-token"]')
            .content,
        }),
      });

      const data = await response.json();

      // Reset form
      this.input.value = "";

      // Add response message to chat (question is already displayed)
      this.addMessageToChat(
        data.response_message,
        true,
        data.knowledge_base_influence
      );

      // Scroll to bottom after response is added
      setTimeout(() => this.scrollToBottom(true), 300);
    } catch (error) {
      console.error("Error:", error);
      this.addMessageToChat(
        {
          content: "I'm sorry, I encountered an error. Please try again.",
          message_type: "answer",
          created_at: new Date(),
        },
        true
      );

      // Scroll to bottom after error message
      setTimeout(() => this.scrollToBottom(true), 300);
    } finally {
      this.setLoadingState(false);
    }
  }

  async addUserQuestionToChat(question) {
    // Create a message object for the user's question
    const userMessage = {
      content: question,
      message_type: "question",
      created_at: new Date().toISOString(),
      id: "temp-" + Date.now(), // Temporary ID for user questions
    };

    // Use the same partial rendering system
    await this.addMessageToChat(userMessage, false, null);
  }

  async addMessageToChat(
    message,
    isTypingResponse = false,
    kbInfluence = null
  ) {
    if (!this.chatHistory) {
      console.error("Chat history element not found!");
      return;
    }

    try {
      // Render the partial using Rails
      const response = await fetch("/jason_ai/render_message", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({
          message: message,
          kb_influence: kbInfluence,
        }),
      });

      if (response.ok) {
        const html = await response.text();

        // Insert the HTML directly without creating an extra wrapper div
        this.chatHistory.insertAdjacentHTML("beforeend", html);

        // Force scroll to bottom for new messages
        this.scrollToBottom(true);
      } else {
        console.error("Failed to render message partial");
      }
    } catch (error) {
      console.error("Error rendering message:", error);
    }
  }

  createTypingMessage(messageElement, message) {
    messageElement.innerHTML = `
      <div class="jason-ai-chat-message__more" data-timestamp="${new Date(
        message.created_at
      ).toLocaleString()}">
        <svg height="16" width="16" viewBox="0 0 24 24" fill="currentColor">
          <circle cx="12" cy="12" r="1"></circle>
          <circle cx="19" cy="12" r="1"></circle>
          <circle cx="5" cy="12" r="1"></circle>
        </svg>
      </div>
      <div class="chat-message__content">
        <span class="typing-indicator">▋</span>
      </div>
      <div class="chat-message__timestamp">
        ${new Date(message.created_at).toLocaleString()}
      </div>
    `;

    this.startTypingEffect(messageElement, message.content);
  }

  createStaticMessage(messageElement, message) {
    messageElement.innerHTML = `
      <div class="jason-ai-chat-message__more" data-timestamp="${new Date(
        message.created_at
      ).toLocaleString()}">
        <svg height="16" width="16" viewBox="0 0 24 24" fill="currentColor">
          <circle cx="12" cy="12" r="1"></circle>
          <circle cx="19" cy="12" r="1"></circle>
          <circle cx="5" cy="12" r="1"></circle>
        </svg>
      </div>
      <div class="chat-message__content">
        ${message.content}
      </div>
      <div class="chat-message__timestamp">
        ${new Date(message.created_at).toLocaleString()}
      </div>
    `;
  }

  startTypingEffect(messageElement, content) {
    const words = content.split(" ");
    let currentWordIndex = 0;

    const typeNextWord = () => {
      if (currentWordIndex < words.length) {
        const contentElement = messageElement.querySelector(
          ".chat-message__content"
        );
        const currentText = contentElement.innerHTML.replace(
          '<span class="typing-indicator">▋</span>',
          ""
        );
        const newText =
          currentText +
          (currentWordIndex > 0 ? " " : "") +
          words[currentWordIndex];
        contentElement.innerHTML =
          newText + '<span class="typing-indicator">▋</span>';
        currentWordIndex++;

        const delay = Math.random() * 100 + 50;
        setTimeout(typeNextWord, delay);
      } else {
        const contentElement = messageElement.querySelector(
          ".chat-message__content"
        );
        contentElement.innerHTML = contentElement.innerHTML.replace(
          '<span class="typing-indicator">▋</span>',
          ""
        );
      }
    };

    setTimeout(typeNextWord, 500);
  }

  scrollToBottom(force = false) {
    if (!this.chatHistory) {
      console.log("JasonAiChat: Chat history not found for scrolling");
      return;
    }

    // Use requestAnimationFrame to ensure DOM is updated
    requestAnimationFrame(() => {
      const scrollContainer = document.querySelector(
        "[data-jason-ai-chat-container='true']"
      );

      if (!scrollContainer) {
        console.log("JasonAiChat: Chat container not found for scrolling");
        return;
      }

      // Check if user is near the bottom (within 100px) or if force is true
      const isNearBottom =
        scrollContainer.scrollTop + scrollContainer.clientHeight >=
        scrollContainer.scrollHeight - 100;

      if (isNearBottom || force) {
        console.log("JasonAiChat: Scrolling to bottom of chat container");

        // Scroll to the very bottom of the container
        scrollContainer.scrollTo({
          top: scrollContainer.scrollHeight - scrollContainer.clientHeight,
          behavior: "smooth",
        });

        // Fallback: force scroll to bottom after animation
        setTimeout(() => {
          scrollContainer.scrollTop =
            scrollContainer.scrollHeight - scrollContainer.clientHeight;
        }, 500);
      } else {
        console.log(
          "JasonAiChat: User is not near bottom, skipping auto-scroll"
        );
      }
    });
  }

  bindFeedbackEvents() {
    // Add click event listeners for feedback buttons
    document.addEventListener("click", (e) => this.handleFeedbackClick(e));
  }

  handleFeedbackClick(e) {
    const feedbackBtn = e.target.closest("[data-feedback-button]");
    if (!feedbackBtn) return;

    e.preventDefault();

    const feedbackContainer = feedbackBtn.closest("[data-feedback-container]");
    const messageId = feedbackContainer.dataset.messageId;
    const feedbackRating = feedbackBtn.dataset.feedback;

    // Prevent double-clicking the same feedback
    if (feedbackBtn.dataset.selected === "true") return;

    // Prevent multiple clicks while processing
    if (feedbackBtn.disabled) return;

    // Create animation burst immediately for responsive feel
    this.createFeedbackBurst(feedbackBtn, feedbackRating);

    // Disable buttons immediately to prevent double-clicking
    this.setFeedbackButtonsState(feedbackContainer, "loading");

    this.submitFeedback(messageId, feedbackRating, feedbackContainer);
  }

  async submitFeedback(messageId, rating, container) {
    try {
      const response = await fetch("/jason_ai/feedback", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document
            .querySelector('[name="csrf-token"]')
            .getAttribute("content"),
        },
        body: JSON.stringify({
          message_id: messageId,
          rating: rating,
        }),
      });

      const result = await response.json();

      if (response.ok) {
        // Update UI to show selected feedback
        this.updateFeedbackUI(container, rating);
        console.log("Feedback submitted successfully:", result);
      } else {
        console.error("Feedback submission failed:", result.error);
        this.setFeedbackButtonsState(container, "error");
        // Re-enable buttons after a delay
        setTimeout(
          () => this.setFeedbackButtonsState(container, "enabled"),
          2000
        );
      }
    } catch (error) {
      console.error("Network error submitting feedback:", error);
      this.setFeedbackButtonsState(container, "error");
      // Re-enable buttons after a delay
      setTimeout(
        () => this.setFeedbackButtonsState(container, "enabled"),
        2000
      );
    }
  }

  updateFeedbackUI(container, selectedRating) {
    const buttons = container.querySelectorAll("[data-feedback-button]");

    buttons.forEach((btn) => {
      const isSelected = btn.dataset.feedback === selectedRating;

      if (isSelected) {
        btn.dataset.selected = "true";
      } else {
        btn.dataset.selected = "false";
      }

      // Disable both buttons permanently after feedback is submitted
      btn.disabled = true;
    });
  }

  setFeedbackButtonsState(container, state) {
    const buttons = container.querySelectorAll("[data-feedback-button]");

    buttons.forEach((btn) => {
      switch (state) {
        case "loading":
          btn.disabled = true;
          break;
        case "error":
          btn.disabled = true;
          break;
        case "enabled":
          btn.disabled = false;
          break;
      }
    });
  }

  createFeedbackBurst(button, rating) {
    const isThumbsUp = rating === "thumbs_up";
    const burstCount = 8; // Number of SVG particles

    // Get the SVG from the clicked button to clone it
    const buttonSvg = button.querySelector("svg");
    if (!buttonSvg) return; // Safety check

    // Get button position
    const buttonRect = button.getBoundingClientRect();
    const centerX = buttonRect.left + buttonRect.width / 2;
    const centerY = buttonRect.top + buttonRect.height / 2;

    // Create burst container
    const burstContainer = document.createElement("div");
    burstContainer.className = "feedback-burst-container";
    burstContainer.style.cssText = `
      position: fixed;
      top: 0;
      left: 0;
      pointer-events: none;
      z-index: 10000;
    `;
    document.body.appendChild(burstContainer);

    // Create individual particles
    for (let i = 0; i < burstCount; i++) {
      const particle = document.createElement("div");
      particle.className = "feedback-particle";

      // Clone the SVG from the button
      const svgClone = buttonSvg.cloneNode(true);
      svgClone.style.cssText = `
        width: 16px;
        height: 16px;
        display: block;
      `;
      particle.appendChild(svgClone);

      // Random angle and distance for burst effect
      const angle =
        (i / burstCount) * Math.PI * 2 + (Math.random() - 0.5) * 0.5;
      const distance = 40 + Math.random() * 60;
      const endX = centerX + Math.cos(angle) * distance;
      const endY = centerY + Math.sin(angle) * distance;

      particle.style.cssText = `
        position: absolute;
        left: ${centerX}px;
        top: ${centerY}px;
        transform: translate(-50%, -50%);
        opacity: 1;
        transition: all 2s cubic-bezier(0.25, 0.46, 0.45, 0.94);
        pointer-events: none;
      `;

      burstContainer.appendChild(particle);

      // Animate particle
      requestAnimationFrame(() => {
        particle.style.transform = `translate(-50%, -50%) translate(${
          endX - centerX
        }px, ${endY - centerY}px) rotate(${Math.random() * 360}deg) scale(0.3)`;
        particle.style.opacity = "0";
      });
    }

    // Clean up after animation
    setTimeout(() => {
      burstContainer.remove();
    }, 800);
  }

  showFlashMessage(message) {
    // Create flash message element following existing pattern
    const flashElement = document.createElement("div");
    flashElement.className = "flashes";
    flashElement.innerHTML = `<div class="flash-notice">${message}</div>`;

    // Add to page (after the existing flashes if any)
    const existingFlashes = document.querySelector(".flashes");
    if (existingFlashes) {
      existingFlashes.parentNode.insertBefore(
        flashElement,
        existingFlashes.nextSibling
      );
    } else {
      // If no existing flashes, add to the top of the main content
      const main = document.querySelector(".jason-ai-main");
      if (main) {
        main.parentNode.insertBefore(flashElement, main);
      } else {
        document.body.insertBefore(flashElement, document.body.firstChild);
      }
    }

    // Remove after 3 seconds
    setTimeout(() => {
      if (flashElement.parentNode) {
        flashElement.parentNode.removeChild(flashElement);
      }
    }, 3000);
  }

  addKnowledgeBaseIndicator(messageElement, kbInfluence) {
    const indicator = document.createElement("div");
    indicator.className = "jason-ai-kb-indicator";

    const influenceText = this.getInfluenceText(kbInfluence);
    indicator.innerHTML = `
      <div class="jason-ai-kb-indicator__icon">📚</div>
      <div class="jason-ai-kb-indicator__content">
        <div class="jason-ai-kb-indicator__text">${influenceText}</div>
        <div class="jason-ai-kb-indicator__confidence">${kbInfluence.confidence_score}% confidence</div>
      </div>
    `;

    // Replace the placeholder comment in the actions section
    const actionsSection = messageElement.querySelector(
      ".jason-ai-chat-message__actions"
    );
    if (actionsSection) {
      const placeholderDiv = actionsSection.querySelector("div");
      if (
        placeholderDiv &&
        placeholderDiv.innerHTML.includes("<!-- Put confidence score here -->")
      ) {
        placeholderDiv.innerHTML = "";
        placeholderDiv.appendChild(indicator);
      }
    }
  }

  getInfluenceText(kbInfluence) {
    const level = kbInfluence.influence_level;
    const count = kbInfluence.sources_count;

    switch (level) {
      case "high":
        return `Based on ${count} knowledge base sources`;
      case "medium":
        return `Informed by ${count} knowledge base sources`;
      case "low":
        return `Partially informed by knowledge base`;
      case "minimal":
        return `Minimal knowledge base influence`;
      default:
        return "Knowledge base influence";
    }
  }
}

if (!window.myMindChatInitialized) {
  window.myMindChatInitialized = true;
  const initChat = () => new JasonAiChat();

  document.readyState === "loading"
    ? document.addEventListener("DOMContentLoaded", initChat)
    : initChat();
}
