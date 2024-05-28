export default {
  mounted() {
    this.adjustHeight();
    this.el.addEventListener("input", () => {
      this.adjustHeight();
    });
  },

  adjustHeight() {
    this.el.style.height = "auto";
    this.el.style.height = `${this.el.scrollHeight}px`;
  },
};
