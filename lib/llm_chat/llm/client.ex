defmodule LlmChat.Llm.Client do
  @moduledoc false
  def chat_stream(openai, messages) do
    chat_request = chat_request(messages: messages)
    openai |> OpenaiEx.Chat.Completions.create!(chat_request, stream: true)
  end

  def cancel_chat_stream(cancel_pid) do
    OpenaiEx.HttpSse.cancel_request(cancel_pid)
  end

  defp chat_request(args) do
    args
    |> Enum.into(%{model: "gpt-4o-mini", temperature: 0.7})
    |> OpenaiEx.Chat.Completions.new()
  end
end
