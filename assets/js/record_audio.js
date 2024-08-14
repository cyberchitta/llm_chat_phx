class Mp3Converter {
  constructor() {
    this.audioContext = new (window.AudioContext || window.webkitAudioContext)();
  }

  async convertToMp3(audioBlob) {
    const audioBuffer = await this.getAudioBuffer(audioBlob);
    const mp3Encoder = new lamejs.Mp3Encoder(1, audioBuffer.sampleRate, 128);
    const mp3Data = this.encodeMp3(mp3Encoder, audioBuffer);
    return new Blob(mp3Data, { type: "audio/mp3" });
  }

  async getAudioBuffer(audioBlob) {
    const arrayBuffer = await audioBlob.arrayBuffer();
    return await this.audioContext.decodeAudioData(arrayBuffer);
  }

  encodeMp3(encoder, audioBuffer) {
    const left = audioBuffer.getChannelData(0);
    const sampleBlockSize = 1152;
    const mp3Data = [];
    for (let i = 0; i < left.length; i += sampleBlockSize) {
      const sampleChunk = left.subarray(i, i + sampleBlockSize);
      const mp3buf = encoder.encodeBuffer(this.convertBuffer(sampleChunk));
      if (mp3buf.length > 0) {
        mp3Data.push(new Int8Array(mp3buf));
      }
    }
    const mp3buf = encoder.flush();
    if (mp3buf.length > 0) {
      mp3Data.push(new Int8Array(mp3buf));
    }
    return mp3Data;
  }

  convertBuffer(arrayBuffer) {
    const data = new Float32Array(arrayBuffer);
    const out = new Int16Array(arrayBuffer.length);
    for (let i = 0; i < data.length; i++) {
      out[i] = data[i] < 0 ? data[i] * 0x8000 : data[i] * 0x7FFF;
    }
    return out;
  }
}

export default {
  mounted() {
    if (typeof lamejs === 'undefined') {
      console.error('Lamejs is not loaded. Make sure to include it in your HTML.');
      return;
    }
    this.mp3Converter = new Mp3Converter()
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
        const mp3Data = await this.mp3Converter.convertToMp3(audioBlob);
        const reader = new FileReader();
        reader.readAsDataURL(mp3Data);
        reader.onloadend = () => {
          const base64AudioMessage = reader.result.split(",")[1];
          this.messageId = `whisper-${Math.random().toString(36).slice(2, 10)}`;
          this.pushEventTo("#new-chat-message", "whisper", {
            audio_data: base64AudioMessage,
            message_id: this.messageId,
            content_type: "audio/mpeg",
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
