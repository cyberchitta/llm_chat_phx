export default {
  mounted() {
    this.handleClick = this.handleClick.bind(this);
    this.handleDocumentClick = this.handleDocumentClick.bind(this);
    this.handleMenuClick = this.handleMenuClick.bind(this);
    this.handleRenameChat = this.handleRenameChat.bind(this);
    this.handleDeleteChat = this.handleDeleteChat.bind(this);

    this.el.addEventListener("click", this.handleClick);
    document.addEventListener("click", this.handleDocumentClick);
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleClick);
    document.removeEventListener("click", this.handleDocumentClick);
  },

  handleClick(event) {
    event.preventDefault();
    event.stopPropagation();
    const menu = document.querySelector("#chat-item-menu");
    const rect = this.el.getBoundingClientRect();
    const { left: x, bottom: y } = rect;
    menu.style.left = `${x}px`;
    menu.style.top = `${y}px`;
    menu.setAttribute("data-chat-id", this.el.getAttribute("data-chat-id"));
    menu.classList.remove("hidden");

    menu.addEventListener("click", this.handleMenuClick);
    document
      .querySelector("#rename-chat")
      .addEventListener("click", this.handleRenameChat);
    document
      .querySelector("#delete-chat")
      .addEventListener("click", this.handleDeleteChat);
  },

  handleDocumentClick(event) {
    const menu = document.querySelector("#chat-item-menu");
    if (!menu.contains(event.target) && !this.el.contains(event.target)) {
      menu.classList.add("hidden");

      menu.removeEventListener("click", this.handleMenuClick);
      document
        .querySelector("#rename-chat")
        .removeEventListener("click", this.handleRenameChat);
      document
        .querySelector("#delete-chat")
        .removeEventListener("click", this.handleDeleteChat);
    }
  },

  handleMenuClick(event) {
    event.stopPropagation();
  },

  handleRenameChat() {
    const menu = document.querySelector("#chat-item-menu");
    const chatId = menu.getAttribute("data-chat-id");
    const chatNameElement = document.querySelector(`#chat-name-${chatId}`);
    if (chatNameElement) {
      chatNameElement.innerHTML = `<input type="text" id="rename-input" value="${chatNameElement.textContent.trim()}" class="input input-bordered input-sm w-full max-w-xs" />`;
      const inputElement = document.querySelector("#rename-input");
      inputElement.focus();
      const finishRename = () => {
        this.pushEventTo(this.el, "rename_chat", {
          id: chatId,
          new_name: inputElement.value,
        });
        inputElement.removeEventListener("blur", finishRename);
        inputElement.removeEventListener("keypress", handleKeyPress);
      };
      const handleKeyPress = (event) => {
        if (event.key === "Enter") {
          inputElement.blur();
        }
      };
      inputElement.addEventListener("blur", finishRename);
      inputElement.addEventListener("keypress", handleKeyPress);

      menu.classList.add("hidden");
    }
  },

  handleDeleteChat() {
    const menu = document.querySelector("#chat-item-menu");
    const chatId = menu.getAttribute("data-chat-id");
    this.pushEventTo(this.el, "delete_chat", { id: chatId });
    menu.classList.add("hidden");
  },
};
