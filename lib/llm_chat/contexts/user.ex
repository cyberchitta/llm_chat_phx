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

  def upsert!(profile) do
    u = %{
      google_id: profile.sub,
      email: profile.email,
      name: profile.name,
      avatar_url: profile.picture
    }

    user = User |> get_by(email: profile.email)
    if user, do: user, else: %User{} |> User.changeset(u) |> insert!()
  end
end
