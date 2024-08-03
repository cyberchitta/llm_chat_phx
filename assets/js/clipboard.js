export default {
  mounted() {
    console.log("Clipboard hook mounted");
    this.handleCopyClick = this.handleCopyClick.bind(this);
    this.el.addEventListener("click", this.handleCopyClick);
  },

  destroyed() {
    this.el.removeEventListener("click", this.handleCopyClick);
  },

  handleCopyClick(event) {
    const button = event.target.closest(".copy-message-btn");
    if (button) {
      const encodedContent = button.getAttribute("data-content");
      const content = this.decodeHTMLEntities(encodedContent);

      navigator.clipboard
        .writeText(content)
        .then(() => {
          console.log("Content copied to clipboard");
        })
        .catch((err) => {
          console.error("Failed to copy: ", err);
        });
    }
  },

  decodeHTMLEntities(text) {
    const textArea = document.createElement("textarea");
    textArea.innerHTML = text;
    const decodedText = textArea.value;
    textArea.remove();
    return decodedText;
  },
};
