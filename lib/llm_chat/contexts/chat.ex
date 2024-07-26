defmodule LlmChat.Contexts.Chat do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.{Chat, Message, User}

  def list_by_period(user_email) do
    from(c in Chat,
      join: u in User,
      on: c.user_id == u.id,
      where: u.email == ^user_email,
      order_by: [desc: c.updated_at],
      select: %{id: c.id, name: c.name, updated_at: c.updated_at}
    )
    |> all()
    |> Enum.map(fn chat -> Map.put(chat, :period, period_label(chat.updated_at)) end)
    |> Enum.chunk_by(& &1.period)
    |> Enum.map(fn chats -> %{label: hd(chats).period, chats: chats} end)
  end

  defp period_label(date) do
    today = Date.utc_today()
    yesterday = Date.add(today, -1)
    one_week_ago = Date.add(today, -7)
    one_month_ago = Date.add(today, -30)

    cond do
      Date.compare(date, today) == :eq -> "Today"
      Date.compare(date, yesterday) == :eq -> "Yesterday"
      Date.compare(date, one_week_ago) in [:eq, :gt] -> "Previous 7 Days"
      Date.compare(date, one_month_ago) in [:eq, :gt] -> "Previous 30 Days"
      true -> "#{Calendar.strftime(date, "%B")} #{date.year}"
    end
  end

  def create(attrs) do
    %Chat{} |> Chat.changeset(attrs) |> insert!()
  end

  def rename(chat_id, new_name) do
    Chat |> get!(chat_id) |> Chat.changeset(%{name: new_name}) |> update!()
  end

  def delete(chat_id) do
    Chat |> get!(chat_id) |> delete!()
  end

  def touch(chat_id) do
    Chat
    |> get!(chat_id)
    |> Chat.changeset(%{})
    |> Ecto.Changeset.put_change(:updated_at, DateTime.utc_now(:second))
    |> update!()
  end

  def details(chat_id) do
    %{
      chat: Chat |> get(chat_id),
      messages:
        chat_id
        |> get_ui_thread()
        |> Enum.map(&Map.put(&1, :sibling_info, get_sibling_info(chat_id, &1)))
    }
  end

  def add_message!(%{parent_id: nil} = attrs) do
    attrs |> Map.put(:path, to_string(attrs.turn_number)) |> insert_message!()
  end

  def add_message!(%{parent_id: parent_id} = attrs) do
    parent_path = Message |> get_by(id: parent_id) |> Map.get(:path)
    attrs |> Map.put(:path, "#{parent_path}.#{attrs.turn_number}") |> insert_message!()
  end

  defp insert_message!(attrs) do
    {:ok, result} =
      transaction(fn ->
        attachments = Enum.map(attrs.attachments, &Map.take(&1, [:url, :content_type, :filename]))
        msg = %Message{} |> Message.changeset(%{attrs | attachments: attachments}) |> insert!()
        update_max_turn_number!(msg.chat_id, msg.turn_number)
        msg
      end)

    result
  end

  defp update_max_turn_number!(chat_id, turn_number) do
    from(c in Chat, where: c.id == ^chat_id)
    |> Ecto.Query.update(
      set: [max_turn_number: fragment("GREATEST(max_turn_number, ?)", ^turn_number)]
    )
    |> update_all([])
  end

  def update_ui_path!(chat_id, path) do
    Chat |> get!(chat_id) |> Chat.changeset(%{ui_path: path}) |> update!()
  end

  defp get_sibling_info(chat_id, message) do
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

  defp get_ui_thread(chat_id) do
    path = Chat |> get!(chat_id) |> Map.get(:ui_path)

    Message
    |> where(chat_id: ^chat_id)
    |> where([m], fragment("? = ? OR starts_with(?, ? || '.')", m.path, ^path, ^path, m.path))
    |> order_by([m], m.turn_number)
    |> all()
  end

  def get_leftmost_path(chat_id, message_id) do
    message = Message |> get_by(id: message_id)

    leftmost_child =
      Message
      |> where([m], m.chat_id == ^chat_id and m.parent_id == ^message_id)
      |> order_by([m], asc: m.turn_number)
      |> limit(1)
      |> one()

    case leftmost_child do
      nil -> message.path
      child -> get_leftmost_path(chat_id, child.id)
    end
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
