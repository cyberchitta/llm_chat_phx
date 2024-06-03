export default {
  mounted() {
    this.adjustHeight = this.adjustHeight.bind(this);

    this.el.addEventListener("input", this.adjustHeight);
    this.adjustHeight();
  },

  destroyed() {
    this.el.removeEventListener("input", this.adjustHeight);
  },

  adjustHeight() {
    this.el.style.height = "auto";
    this.el.style.height = `${this.el.scrollHeight}px`;
  },
};
