defmodule LlmChat.Llm.Chat do
  alias LlmChat.Llm.{Context, Client, Streamer}

  def initiate_stream(prompt, attachments) do
    openai = Application.get_env(:llm_chat, :openai_api_key) |> OpenaiEx.new()
    messages = Context.create_messages(prompt, attachments)
    openai |> Client.stream(messages)
  end

  def process_stream(receiver, stream) do
    Streamer.process_stream(receiver, stream)
  end

  def cancel_stream(cancel_pid) do
    Client.cancel_stream(cancel_pid)
  end
end
