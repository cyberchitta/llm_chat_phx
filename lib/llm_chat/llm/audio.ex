defmodule LlmChat.Llm.Audio do
  @moduledoc false
  require Logger
  alias OpenaiEx
  alias OpenaiEx.Audio.{Speech, Transcription}

  def initiate_tts(receiver, message_id, text) do
    Task.start(fn ->
      case text_to_speech(text) do
        {:ok, audio_content} -> send(receiver, {:audio_ready, message_id, audio_content})
        {:error, reason} -> send(receiver, {:audio_error, message_id, reason})
      end
    end)
  end

  defp text_to_speech(text, voice \\ "alloy") do
    openai = Application.get_env(:llm_chat, :openai_api_key) |> OpenaiEx.new()
    speech_req = Speech.new(model: "tts-1", voice: voice, input: text, response_format: "mp3")
    openai |> Speech.create(speech_req)
  end

  def initiate_transcription(receiver, message_id, audio_content, content_type) do
    Task.start(fn ->
      case transcribe(audio_content, content_type) do
        {:ok, transcript} -> send(receiver, {:transcript_ready, message_id, transcript["text"]})
        {:error, reason} -> send(receiver, {:transcript_error, message_id, reason})
      end
    end)
  end

  defp transcribe(audio_content, content_type) do
    openai = Application.get_env(:llm_chat, :openai_api_key) |> OpenaiEx.new()
    extension = mime_type_to_extension(content_type)
    decoded_audio = Base.decode64!(audio_content)
    audio_file = OpenaiEx.new_file(name: "audio#{extension}", content: decoded_audio)
    transcription_req = Transcription.new(file: audio_file, model: "whisper-1")
    Transcription.create(openai, transcription_req)
  end

  defp mime_type_to_extension(mime_type) do
    case mime_type do
      "audio/wav" -> ".wav"
      "audio/mpeg" -> ".mp3"
      "audio/mp4" -> ".mp4"
      # fallback
      _ -> ".bin"
    end
  end
end
