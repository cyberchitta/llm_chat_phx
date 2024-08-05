defmodule LlmChat.Llm.Audio do
  @moduledoc false
  require Logger
  alias OpenaiEx
  alias OpenaiEx.Audio.Speech

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
end
