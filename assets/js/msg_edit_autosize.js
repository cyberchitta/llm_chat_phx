export default {
  mounted() {
    this.adjustHeight = this.adjustHeight.bind(this);
    this.el.addEventListener("input", this.adjustHeight);
    this.adjustHeight();

    document.querySelectorAll('[id^="edit-textarea-"]').forEach((textarea) => {
      textarea.addEventListener("input", this.adjustHeight);
      this.adjustHeight.call(textarea);
    });
  },

  destroyed() {
    this.el.removeEventListener("input", this.adjustHeight);
  },

  adjustHeight() {
    this.style.height = "auto";
    this.style.height = `${Math.max(this.scrollHeight, 100)}px`; // Ensure minimum height of 100px
  },
};
