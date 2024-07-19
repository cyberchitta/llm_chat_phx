defmodule LlmChat.Files.S3Uploader do
  @moduledoc false

  def upload(file_path, file_name, content_type) do
    file_binary = File.read!(file_path)

    bucket()
    |> ExAws.S3.put_object(file_name, file_binary, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} -> {:ok, url(file_name)}
      {:error, reason} -> {:error, reason}
    end
  end

  def url(file_name) do
    config = ExAws.Config.new(:s3)
    "#{config.scheme}#{config.host}:#{config.port}/#{bucket()}/#{file_name}"
  end

  defp bucket() do
    Application.get_env(:llm_chat, :s3_bucket_name)
  end
end
