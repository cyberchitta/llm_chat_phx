export default {
  mounted() {
    this.startRecording = this.startRecording.bind(this);
    this.stopRecording = this.stopRecording.bind(this);
    this.handleTranscription = this.handleTranscription.bind(this);
    this.handleTranscriptionError = this.handleTranscriptionError.bind(this);

    this.el.addEventListener("click", this.startRecording);
    this.handleEvent("transcription_ready", this.handleTranscription);
    this.handleEvent("transcription_error", this.handleTranscriptionError);
  },

  destroyed() {
    this.el.removeEventListener("click", this.startRecording);
  },

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];

      this.mediaRecorder.addEventListener("dataavailable", (event) => {
        this.audioChunks.push(event.data);
      });

      this.mediaRecorder.addEventListener("stop", async () => {
        const audioBlob = new Blob(this.audioChunks, { type: "audio/wav" });
        const reader = new FileReader();
        reader.readAsDataURL(audioBlob);
        reader.onloadend = () => {
          const base64AudioMessage = reader.result.split(",")[1];
          this.messageId = `whisper-${Math.random().toString(36).slice(2, 10)}`;
          this.pushEventTo("#new-chat-message", "whisper", {
            audio_data: base64AudioMessage,
            message_id: this.messageId,
            content_type: audioBlob.type,
          });
        };
      });

      this.mediaRecorder.start();
      this.el.querySelector("span").classList.remove("hero-microphone");
      this.el.querySelector("span").classList.add("hero-stop");
      this.el.removeEventListener("click", this.startRecording);
      this.el.addEventListener("click", this.stopRecording);
    } catch (err) {
      console.error("Error accessing microphone:", err);
      alert(
        "Error accessing microphone. Please ensure you have given permission to use the microphone."
      );
    }
  },

  stopRecording() {
    this.mediaRecorder.stop();
    this.el.querySelector("span").classList.remove("hero-stop");
    this.el.querySelector("span").classList.add("hero-microphone");
    this.el.removeEventListener("click", this.stopRecording);
    this.el.addEventListener("click", this.startRecording);
  },

  handleTranscription(payload) {
    if (payload.message_id === this.messageId) {
      const textArea = document.querySelector("#prompt-textarea");
      console.log(payload)
      textArea.value = payload.text;
      textArea.dispatchEvent(new Event("input", { bubbles: true }));
    }
  },

  handleTranscriptionError(payload) {
    if (payload.message_id === this.messageId) {
      console.error("Transcription error:", payload.reason);
      alert(`Transcription failed: ${payload.reason}`);
    }
  },
};
