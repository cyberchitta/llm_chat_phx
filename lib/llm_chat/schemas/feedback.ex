defmodule LlmChat.Schemas.Feedback do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "feedbacks" do
    field(:type, :string)

    belongs_to(:message, LlmChat.Schemas.Message)

    timestamps()
  end

  @doc false
  def changeset(feedback, attrs) do
    feedback
    |> cast(attrs, [:type, :message_id])
    |> validate_required([:type, :message_id])
    |> validate_inclusion(:type, ["like", "dislike"])
    |> unique_constraint([:message_id])
  end
end
