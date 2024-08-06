defmodule LlmChat.Llm.Streamer do
  @moduledoc false
  def process_stream(receiver, stream) do
    stream.body_stream |> content_stream() |> send_chunks(receiver)
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
