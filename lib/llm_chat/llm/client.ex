defmodule LlmChat.Llm.Client do
  @moduledoc false
  def chat_stream(openai, messages, preset) do
    chat_request = chat_request(messages, preset)
    openai |> OpenaiEx.Chat.Completions.create!(chat_request, stream: true)
  end

  def cancel_chat_stream(cancel_pid) do
    OpenaiEx.HttpSse.cancel_request(cancel_pid)
  end

  defp chat_request(messages, preset) do
    %{
      model: preset.model,
      messages: messages,
      temperature: preset.settings["temperature"] || 0.7
    } |> IO.inspect()
    |> OpenaiEx.Chat.Completions.new()
  end
end
