defmodule LlmChat.Llm.Streamer do
  @moduledoc false
  def process_stream(receiver, stream) do
    stream.body_stream |> data_stream() |> send_chunks(receiver)
  end

  defp data_stream(base_stream) do
    base_stream
    |> Stream.flat_map(& &1)
    |> Stream.map(fn %{data: data} ->
      case data do
        %{"usage" => usage} when not is_nil(usage) ->
          %{usage: usage}

        %{"choices" => choices} when choices != [] ->
          case List.first(choices) do
            %{"delta" => %{}, "finish_reason" => "stop"} -> %{}
            %{"delta" => delta} -> %{content: delta |> Map.get("content")}
          end
      end
    end)
    |> Stream.reject(fn map -> map_size(map) == 0 end)
  end

  defp send_chunks(data_stream, receiver) do
    data_stream
    |> Enum.each(fn
      %{content: content} -> send(receiver, {:next_chunk, content})
      %{usage: usage} -> send(receiver, {:token_usage, usage})
    end)

    send(receiver, :end_of_stream)
  end
end
