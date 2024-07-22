defmodule LlmChat.Llm.Chat do
  @moduledoc false
  require Logger
  alias OpenaiEx
  alias OpenaiEx.{ChatMessage, MsgContent}

  @supported_image_types ["image/jpeg", "image/png", "image/gif", "image/webp"]
  @supported_text_types ["text/plain", "text/markdown"]

  def initiate_stream(prompt, attachments) do
    openai = Application.get_env(:llm_chat, :openai_api_key) |> OpenaiEx.new()
    messages = create_messages(prompt, attachments)
    openai |> stream(messages)
  end

  def process_stream(receiver, stream) do
    stream.body_stream |> content_stream() |> send_chunks(receiver)
  end

  def cancel_stream(cancel_pid) do
    OpenaiEx.HttpSse.cancel_request(cancel_pid)
  end

  defp create_messages(prompt, attachments) do
    [
      ChatMessage.system("You are an AI assistant."),
      create_user_message(prompt, attachments)
    ]
  end

  defp create_user_message(prompt, []) do
    ChatMessage.user(prompt)
  end

  defp create_user_message(prompt, attachments) do
    attachments
    |> Enum.reduce({prompt, []}, &attach/2)
    |> to_message()
    |> ChatMessage.user()
  end

  defp attach(a, {acc_text, acc_images}) do
    case a.content_type do
      type when type in @supported_text_types ->
        {:ok, text_content} = get_content(a)
        {acc_text <> "\n\n--- Attachment: #{a.filename} ---\n" <> text_content, acc_images}

      type when type in @supported_image_types ->
        {acc_text, acc_images ++ [a]}

      _ ->
        Logger.warning("Unsupported attachment type: #{a.content_type} for file #{a.filename}")
        {acc_text, acc_images}
    end
  end

  defp get_content(attachment) do
    cond do
      Map.has_key?(attachment, :content) -> {:ok, attachment.content}
      Map.has_key?(attachment, :url) -> LlmChat.Files.S3Uploader.download(attachment.url)
      true -> {:error, "Unable to read attachment content"}
    end
  end

  defp to_message({text_content, images}) do
    if Enum.empty?(images) do
      text_content
    else
      [MsgContent.text(text_content) | images |> Enum.map(&MsgContent.image_url(&1.url))]
    end
  end

  defp create_request(args) do
    args
    |> Enum.into(%{model: "gpt-4o-mini", temperature: 0.7})
    |> OpenaiEx.Chat.Completions.new()
  end

  defp stream(openai, messages) do
    chat_request = create_request(messages: messages)
    openai |> OpenaiEx.Chat.Completions.create!(chat_request, stream: true)
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
