export default {
  mounted() {
    this.scrollToBottom();
  },

  updated() {
    this.scrollToBottom();
  },

  scrollToBottom() {
    const finalMessage = document.getElementById("current-response");
    if (finalMessage) {
      const container = finalMessage.parentElement;
      container.scrollTop = container.scrollHeight - container.clientHeight;
    }
  },
};
