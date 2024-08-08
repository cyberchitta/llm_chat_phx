defmodule LlmChat.Llm.Context do
  @moduledoc false
  alias OpenaiEx.ChatMessage
  alias OpenaiEx.MsgContent
  require Logger

  @supported_image_types ["image/jpeg", "image/png", "image/gif", "image/webp"]
  @supported_text_types ["text/plain", "text/markdown"]

  def create_messages(prompt, attachments, preset) do
    [
      ChatMessage.system(preset.settings["system_prompt"]),
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
end
