defmodule LlmChat.Contexts.ChatApiCall do
  @moduledoc false
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.ChatApiCall

  def start(name, message_ids, attachment_ids) do
    %{}
    |> Map.merge(%{
      preset_name: name,
      contents: %{message_ids: message_ids, attachment_ids: attachment_ids},
      start_time: DateTime.utc_now()
    })
  end

  def finish(api_call, output_id) do
    api_call |> Map.put(:output_id, output_id) |> duration()
  end

  def with_token_counts(api_call, input, output, total) do
    api_call |> Map.merge(%{input_tokens: input, output_tokens: output, total_tokens: total})
  end

  defp duration(api_call) do
    duration_ms = DateTime.utc_now() |> DateTime.diff(api_call.start_time, :millisecond)
    api_call |> Map.delete(:start_time) |> Map.put(:duration_ms, duration_ms)
  end

  def create!(attrs) do
    %ChatApiCall{} |> ChatApiCall.changeset(attrs) |> insert!()
  end
end
