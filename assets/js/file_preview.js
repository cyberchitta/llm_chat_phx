export default {
  mounted() {
    this.handleRemoveFile = this.handleRemoveFile.bind(this);
    this.el.addEventListener("click", this.handleRemoveFile);
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleRemoveFile);
  },

  handleRemoveFile(event) {
    if (event.target.closest(".remove-file")) {
      const ref = event.target.closest(".remove-file").dataset.ref;
      this.pushEventTo(this.el, "cancel-upload", { ref });
    }
  },
};
