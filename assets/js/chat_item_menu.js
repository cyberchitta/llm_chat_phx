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
      if (menu.classList.contains("hidden")) {
        menu.classList.remove("hidden");
      } else {
        menu.classList.add("hidden");
      }
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
  },
};
