defmodule LlmChat.Contexts.Message do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Contexts.Conversation
  alias LlmChat.Schemas.Message

  def add_message!(%{parent_id: nil} = attrs) do
    attrs |> Map.put(:path, Conversation.msg_path(nil, attrs.turn_number)) |> insert_message!()
  end

  def add_message!(%{parent_id: parent_id} = attrs) do
    parent_path = Message |> get_by(id: parent_id) |> Map.get(:path)
    attrs |> Map.put(:path, Conversation.msg_path(parent_path, attrs.turn_number)) |> insert_message!()
  end

  defp insert_message!(attrs) do
    attachments = Enum.map(attrs.attachments, &Map.take(&1, [:url, :content_type, :filename]))

    %Message{}
    |> Message.changeset(%{attrs | attachments: attachments})
    |> insert!()
    |> LlmChat.RepoPostgres.preload(:feedback)
  end

  def get_sibling_info(chat_id, message) do
    siblings = get_siblings(chat_id, message.parent_id)
    sibling_ids = Enum.map(siblings, & &1.id)
    current_index = Enum.find_index(sibling_ids, &(&1 == message.id))
    %{current: current_index + 1, total: length(siblings), sibling_ids: sibling_ids}
  end

  defp get_siblings(chat_id, parent_id) do
    Message
    |> where([m], m.chat_id == ^chat_id)
    |> where_parent_id_is(parent_id)
    |> order_by([m], m.turn_number)
    |> all()
  end

  defp where_parent_id_is(query, nil), do: where(query, [m], is_nil(m.parent_id))
  defp where_parent_id_is(query, parent_id), do: where(query, [m], m.parent_id == ^parent_id)

  def get_ui_thread(chat_id, path) do
    Message
    |> where(chat_id: ^chat_id)
    |> where([m], fragment("? = ? OR starts_with(?, ? || '.')", m.path, ^path, ^path, m.path))
    |> order_by([m], m.turn_number)
    |> Ecto.Query.preload(:feedback)
    |> all()
  end

  def msg(chat_id, parent_id, turn_number) do
    %{id: nil, chat_id: chat_id, parent_id: parent_id, turn_number: turn_number}
  end

  def with_content(msg, content \\ "", attachments \\ []) do
    msg |> Map.put(:content, content) |> Map.put(:attachments, attachments)
  end

  def to_user(msg) do
    msg |> with_role("user")
  end

  def to_assistant(msg) do
    msg |> with_role("assistant")
  end

  defp with_role(attrs, role) do
    attrs
    |> Map.take([:id, :chat_id, :parent_id, :turn_number, :path, :content, :attachments])
    |> Map.put(:role, role)
  end
end
