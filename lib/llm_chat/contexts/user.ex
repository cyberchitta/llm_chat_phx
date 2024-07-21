defmodule LlmChat.Contexts.User do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres

  alias LlmChat.Schemas.{User, Chat}

  def get_by_email(user_email) do
    User |> get_by(email: user_email)
  end

  def list_chats(user_id) do
    from(c in Chat,
      where: c.user_id == ^user_id,
      select: %{id: c.id, name: c.name}
    )
    |> all()
  end

  def upsert(p) do
    u = %{google_id: p.sub, email: p.email, name: p.name, avatar_url: p.picture}

    case User |> get_by(email: p.email) do
      nil -> %User{} |> User.changeset(u) |> insert()
      user -> {:ok, user}
    end
  end
end
