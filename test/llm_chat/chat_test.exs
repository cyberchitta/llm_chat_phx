defmodule LlmChat.ChatTest do
  use LlmChat.DataCase

  alias LlmChat.Contexts.Chat

  setup do
    #    LlmChat.Fixtures.seed_data()
    :ok
  end

  @tag :seeded
  test "get_chat_details/1 returns the chat details and messages" do
    chat = LlmChat.RepoPostgres.one(from(c in LlmChat.Schemas.Chat, limit: 1))
    chat_details = Chat.details(chat.id, chat.ui_path)

    assert chat_details.chat.id == chat.id
    assert chat_details.chat.name != nil
    assert chat_details.chat.user_id != nil

    assert length(chat_details.messages) > 0
    assert Enum.all?(chat_details.messages, fn message -> message.id != nil end)
    assert Enum.all?(chat_details.messages, fn message -> message.role != nil end)
    assert Enum.all?(chat_details.messages, fn message -> message.content != nil end)
    assert Enum.all?(chat_details.messages, fn message -> message.inserted_at != nil end)
  end
end
