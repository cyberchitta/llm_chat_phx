defmodule LlmChat.Schemas.User do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "users" do
    field(:google_id, :string)
    field(:email, :string)
    field(:name, :string)
    field(:avatar_url, :string)

    has_many(:chats, LlmChat.Schemas.Chat, foreign_key: :user_id)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :google_id, :email, :name, :avatar_url])
    |> validate_required([:google_id, :email, :name])
    |> unique_constraint(:google_id)
    |> unique_constraint(:email)
  end
end
