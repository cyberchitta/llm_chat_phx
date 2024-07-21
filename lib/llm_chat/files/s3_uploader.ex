defmodule LlmChat.Files.S3Uploader do
  @moduledoc false

  def upload(path, filename, content_type) do
    body = File.read!(path)

    bucket()
    |> ExAws.S3.put_object(filename, body, content_type: content_type)
    |> ExAws.request()
    |> case do
      {:ok, _} ->
        {:ok,
         %{url: url(filename), content_type: content_type, filename: filename, content: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def url(filename) do
    config = ExAws.Config.new(:s3)
    "#{config.scheme}#{config.host}:#{config.port}/#{bucket()}/#{filename}"
  end

  def download(url) do
    parsed_url = URI.parse(url)
    bucket = bucket()
    object_key = String.trim_leading(parsed_url.path, "/#{bucket}/")

    case ExAws.S3.get_object(bucket, object_key) |> ExAws.request() do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, _} -> {:error, nil}
    end
  end

  defp bucket() do
    Application.get_env(:llm_chat, :s3_bucket_name)
  end
end
