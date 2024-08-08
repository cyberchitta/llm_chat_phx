defmodule LlmChat.Contexts.Feedback do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.Feedback

  def upsert(attrs) do
    %Feedback{}
    |> Feedback.changeset(attrs)
    |> insert(on_conflict: [set: [type: attrs.type]], conflict_target: [:message_id])
  end

  def delete_feedback(message_id) do
    from(f in Feedback, where: f.message_id == ^message_id) |> delete_all()
  end

  def get_feedback(message_id) do
    Feedback |> get_by(message_id: message_id)
  end
end
