export default {
  mounted() {
    this.handleEvent("toggle_sidebar", () => {
      const sidebar = document.querySelector("#sidebar");
      if (sidebar.classList.contains("hidden")) {
        sidebar.classList.remove("hidden");
        sidebar.classList.add("daisyui-animation-slide-in");
        setTimeout(
          () => sidebar.classList.remove("daisyui-animation-slide-in"),
          300
        );
      } else {
        sidebar.classList.add("daisyui-animation-slide-out");
        setTimeout(() => {
          sidebar.classList.remove("daisyui-animation-slide-out");
          sidebar.classList.add("hidden");
        }, 300);
      }
    });
  },
};
