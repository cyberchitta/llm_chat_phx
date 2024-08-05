export default {
  mounted() {
    this.handleClick = this.handleClick.bind(this);
    this.audioContext = null;
    this.isPlaying = false;
    this.currentSource = null;
    this.el.addEventListener("click", this.handleClick);
    console.log("PlayAudio hook mounted");
  },

  destroyed() {
    if (this.audioContext) {
      this.audioContext.close();
    }
    this.el.removeEventListener("click", this.handleClick);
    console.log("PlayAudio hook destroyed");
  },

  async handleClick(event) {
    const button = event.currentTarget;
    const messageId = button.id.replace("audio-button-", "");
    console.log(`Button clicked for message ID: ${messageId}`);

    if (this.isPlaying) {
      console.log("Stopping playback");
      this.stopPlayback(button);
      return;
    }

    this.isPlaying = true;
    this.setButtonState(button, "loading");

    try {
      await this.initializeAudioContext();
      await this.playShortSilence();

      const audioContent = await this.fetchAudioContent(messageId);
      console.log("Audio content fetched, length:", audioContent.length);

      const arrayBuffer = this.base64ToArrayBuffer(audioContent);
      console.log("ArrayBuffer created, byte length:", arrayBuffer.byteLength);

      const audioBuffer = await this.decodeAudioData(arrayBuffer);
      console.log("Audio data decoded successfully");

      this.playAudio(audioBuffer, button);
    } catch (error) {
      console.error("Error in audio processing:", error);
      alert("Failed to play audio. Please try again.");
      this.isPlaying = false;
      this.setButtonState(button, "play");
    }
  },

  async initializeAudioContext() {
    if (!this.audioContext) {
      this.audioContext = new (window.AudioContext ||
        window.webkitAudioContext)();
      console.log("AudioContext initialized");
    }
    if (this.audioContext.state === "suspended") {
      await this.audioContext.resume();
      console.log("AudioContext resumed");
    }
  },

  async playShortSilence() {
    const silenceBuffer = this.audioContext.createBuffer(1, 1, 22050);
    const source = this.audioContext.createBufferSource();
    source.buffer = silenceBuffer;
    source.connect(this.audioContext.destination);
    source.start();
    console.log("Short silence played to wake up AudioContext");
  },

  async fetchAudioContent(messageId) {
    return new Promise((resolve, reject) => {
      console.log("Pushing text_to_speech event to server");
      this.pushEvent("narrate", { message_id: messageId });
      this.handleEvent("audio_ready", (payload) => {
        console.log("Received audio_ready event");
        if (payload.message_id === messageId) {
          resolve(payload.audio_content);
        } else {
          console.log("Received audio_ready for different message ID");
        }
      });
      this.handleEvent("audio_error", (payload) => {
        console.log("Received audio_error event");
        if (payload.message_id === messageId) {
          reject(new Error("Failed to generate audio"));
        }
      });
    });
  },

  base64ToArrayBuffer(base64) {
    const binaryString = atob(base64);
    const len = binaryString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
      bytes[i] = binaryString.charCodeAt(i);
    }
    return bytes.buffer;
  },

  async decodeAudioData(arrayBuffer) {
    try {
      const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);
      console.log(`Audio duration: ${audioBuffer.duration} seconds`);
      return audioBuffer;
    } catch (decodeError) {
      console.error("Error decoding audio data:", decodeError);
      throw decodeError;
    }
  },

  playAudio(audioBuffer, button) {
    const source = this.audioContext.createBufferSource();
    source.buffer = audioBuffer;

    const gainNode = this.audioContext.createGain();
    gainNode.gain.setValueAtTime(1, this.audioContext.currentTime);
    source.connect(gainNode);
    gainNode.connect(this.audioContext.destination);

    source.onended = () => {
      console.log("Audio playback ended");
      this.isPlaying = false;
      this.currentSource = null;
      this.setButtonState(button, "play");
    };

    console.log("Starting audio playback");
    source.start(0);
    this.currentSource = source;
    this.setButtonState(button, "stop");

    // Fallback timer in case onended doesn't fire
    setTimeout(() => {
      if (this.isPlaying) {
        console.log("Forcing playback end due to timeout");
        this.stopPlayback(button);
      }
    }, audioBuffer.duration * 1000 + 1000); // Audio duration + 1 second buffer
  },

  stopPlayback(button) {
    if (this.currentSource) {
      this.currentSource.stop();
      this.currentSource = null;
    }
    this.isPlaying = false;
    this.setButtonState(button, "play");
  },

  setButtonState(button, state) {
    button.classList.remove("loading");
    button.disabled = false;

    let icon;
    switch (state) {
      case "play":
        icon =
          '<path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 010 12.728M16.463 8.288a5.25 5.25 0 010 7.424M6.75 8.25l4.72-4.72a.75.75 0 011.28.53v15.88a.75.75 0 01-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 012.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75z" />';
        break;
      case "stop":
        icon =
          '<path stroke-linecap="round" stroke-linejoin="round" d="M5.25 7.5A2.25 2.25 0 017.5 5.25h9a2.25 2.25 0 012.25 2.25v9a2.25 2.25 0 01-2.25 2.25h-9a2.25 2.25 0 01-2.25-2.25v-9z" />';
        break;
      case "loading":
        button.classList.add("loading");
        icon = "";
        break;
    }

    button.innerHTML = `<span class="flex h-[30px] w-[30px] items-center justify-center"><svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">${icon}</svg></span>`;
  },
};
