defmodule LlmChat.Llm.Chat do
  @moduledoc false
  alias OpenaiEx
  alias OpenaiEx.ChatMessage

  def initiate_stream(prompt) do
    openai = Application.get_env(:llm_chat, :openai_api_key) |> OpenaiEx.new()
    messages = create_messages(prompt)
    openai |> stream(messages)
  end

  def process_stream(receiver, stream) do
    stream.body_stream |> content_stream() |> send_chunks(receiver)
  end

  def cancel_stream(cancel_pid) do
    OpenaiEx.HttpSse.cancel_request(cancel_pid)
  end

  defp create_messages(prompt) do
    [
      ChatMessage.system("You are an AI assistant."),
      ChatMessage.user(prompt)
    ]
  end

  defp create_request(args) do
    args
    |> Enum.into(%{model: "gpt-3.5-turbo", temperature: 0.7})
    |> OpenaiEx.Chat.Completions.new()
  end

  defp stream(openai, messages) do
    chat_request = create_request(messages: messages)
    openai |> OpenaiEx.Chat.Completions.create(chat_request, stream: true)
  end

  defp content_stream(base_stream) do
    base_stream
    |> Stream.flat_map(& &1)
    |> Stream.map(fn %{data: d} -> d |> Map.get("choices") |> List.first() |> Map.get("delta") end)
    |> Stream.filter(fn map -> map |> Map.has_key?("content") end)
    |> Stream.map(fn map -> map |> Map.get("content") end)
  end

  defp send_chunks(content_stream, receiver) do
    content_stream |> Enum.each(fn chunk -> send(receiver, {:next_chunk, chunk}) end)
    send(receiver, :end_of_stream)
  end
end
