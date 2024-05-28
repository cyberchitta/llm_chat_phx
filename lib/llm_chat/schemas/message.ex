defmodule LlmChat.Schemas.Message do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "messages" do
    field(:content, :string)
    field(:role, :string)
    field(:turn_number, :integer)

    belongs_to(:chat, LlmChat.Schemas.Chat, foreign_key: :chat_id, type: Ecto.UUID)

    belongs_to(:original_message, LlmChat.Schemas.Message,
      foreign_key: :original_message_id,
      type: Ecto.UUID
    )

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :role, :chat_id, :turn_number, :original_message_id])
    |> validate_required([:content, :role, :chat_id, :turn_number])
    |> validate_inclusion(:role, ["assistant", "user"])
    |> assoc_constraint(:chat)
    |> assoc_constraint(:original_message)
  end
end
