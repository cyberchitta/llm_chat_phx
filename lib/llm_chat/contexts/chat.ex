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

  def add_message!(%{parent_id: nil} = attrs) do
    attrs |> Map.put(:path, to_string(attrs.turn_number)) |> insert_message!()
  end

  def add_message!(%{parent_id: parent_id} = attrs) do
    parent_path = get_by!(Message, parent_id: parent_id).path
    attrs |> Map.put(:path, "#{parent_path}.#{attrs.turn_number}") |> insert_message!()
  end

  defp insert_message!(attrs) do
    attachments = Enum.map(attrs.attachments, &Map.take(&1, [:url, :content_type, :filename]))
    %Message{} |> Message.changeset(%{attrs | attachments: attachments}) |> insert!()
  end

  def update_ui_path!(chat_id, path) do
    Chat |> get!(chat_id) |> Chat.changeset(%{ui_path: path}) |> update!()
  end

  def get_siblings(chat_id, parent_id) do
    Message
    |> where(chat_id: ^chat_id, parent_id: ^parent_id)
    |> order_by([m], m.turn_number)
    |> all()
  end

  def get_descendants(chat_id, path) do
    Message
    |> where(chat_id: ^chat_id)
    |> where([m], like(m.path, ^"#{path}.%"))
    |> order_by([m], m.path)
    |> all()
  end

  def get_ui_thread(chat_id) do
    chat = Chat |> get!(chat_id)

    Message
    |> where(chat_id: ^chat_id)
    |> where([m], fragment("? ~ ('^' || ? || '($|\\.)')", m.path, ^chat.ui_path))
    |> order_by([m], m.turn_number)
    |> all()
  end

  def details(chat_id) do
    %{chat: Chat |> get(chat_id), messages: chat_id |> get_ui_thread()}
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
