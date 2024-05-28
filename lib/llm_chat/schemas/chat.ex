defmodule LlmChat.Schemas.Chat do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "chats" do
    field(:name, :string)

    belongs_to(:user, LlmChat.Schemas.User, foreign_key: :user_id, type: Ecto.UUID)
    has_many(:messages, LlmChat.Schemas.Message, foreign_key: :chat_id)

    timestamps()
  end

  def changeset(chat, attrs) do
    chat
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> assoc_constraint(:user)
  end
end
