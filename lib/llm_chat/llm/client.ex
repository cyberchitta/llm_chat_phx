defmodule LlmChat.Llm.Client do
  @moduledoc false
  def create_request(args) do
    args
    |> Enum.into(%{model: "gpt-4o-mini", temperature: 0.7})
    |> OpenaiEx.Chat.Completions.new()
  end

  def stream(openai, messages) do
    chat_request = create_request(messages: messages)
    openai |> OpenaiEx.Chat.Completions.create!(chat_request, stream: true)
  end

  def cancel_stream(cancel_pid) do
    OpenaiEx.HttpSse.cancel_request(cancel_pid)
  end
end
