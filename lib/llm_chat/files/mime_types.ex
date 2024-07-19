defmodule LlmChat.Files.MimeTypes do
  @moduledoc false

  # includes all of https://platform.openai.com/docs/assistants/tools/file-search/supported-files
  defp types do
    [
      {".c", "text/x-c"},
      {".cs", "text/x-csharp"},
      {".cpp", "text/x-c++"},
      {".doc", "application/msword"},
      {".docx", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
      {".html", "text/html"},
      {".java", "text/x-java"},
      {".json", "application/json"},
      {".md", "text/markdown"},
      {".pdf", "application/pdf"},
      {".php", "text/x-php"},
      {".pptx", "application/vnd.openxmlformats-officedocument.presentationml.presentation"},
      {".py", "text/x-python"},
      {".rb", "text/x-ruby"},
      {".tex", "text/x-tex"},
      {".txt", "text/plain"},
      {".css", "text/css"},
      {".js", "text/javascript"},
      {".sh", "application/x-sh"},
      {".ts", "application/typescript"},
      {".jpg", "image/jpeg"},
      {".jpeg", "image/jpeg"},
      {".png", "image/png"},
      {".gif", "image/gif"},
      {".svg", "image/svg+xml"},
      {".mp3", "audio/mpeg"},
      {".wav", "audio/wav"},
      {".mp4", "video/mp4"},
      {".avi", "video/x-msvideo"},
      {".mov", "video/quicktime"}
    ]
  end

  def guess(filename) do
    extension = Path.extname(filename)

    case Enum.find(types(), fn {ext, _} -> ext == extension end) do
      {_, mime_type} -> mime_type
      nil -> "application/octet-stream"
    end
  end
end
