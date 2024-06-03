export default {
  mounted() {
    this.el.addEventListener("click", (event) => {
      event.preventDefault();
      event.stopPropagation();
      const menu = document.querySelector("#chat-item-menu");
      const rect = this.el.getBoundingClientRect();
      const { left: x, bottom: y } = rect;
      menu.style.left = `${x}px`;
      menu.style.top = `${y}px`;
      menu.setAttribute("data-chat-id", this.el.getAttribute("data-chat-id")); // Set chat ID for the menu
      menu.classList.remove("hidden");
    });
    document.addEventListener("click", (event) => {
      const menu = document.querySelector("#chat-item-menu");
      if (!menu.contains(event.target) && !this.el.contains(event.target)) {
        menu.classList.add("hidden");
      }
    });
    const menu = document.querySelector("#chat-item-menu");
    menu.addEventListener("click", (event) => {
      event.stopPropagation();
    });
    document.querySelector("#rename-chat").addEventListener("click", () => {
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
      }
      menu.classList.add("hidden");
    });
    document.querySelector("#delete-chat").addEventListener("click", () => {
      const chatId = menu.getAttribute("data-chat-id");
      this.pushEventTo(this.el, "delete_chat", { id: chatId });
      menu.classList.add("hidden");
    });
  },
};
