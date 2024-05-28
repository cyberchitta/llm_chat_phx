defmodule LlmChat.UserTest do
  use LlmChat.DataCase

  alias LlmChat.Contexts.User

  setup do
    #    LlmChat.Fixtures.seed_data()
    :ok
  end

  @tag :seeded
  test "list_chats/1 returns the chats for a user" do
    user = LlmChat.RepoPostgres.one(from(c in LlmChat.Schemas.User, limit: 1))
    # user = LlmChat.RepoPostgres.get_by(LlmChat.Schemas.User, email: "user1@example.com")
    chats = User.list_chats(user.id)

    assert length(chats) > 0
    assert Enum.all?(chats, fn chat -> chat.id != nil end)
    assert Enum.all?(chats, fn chat -> chat.name != nil end)
  end
end
