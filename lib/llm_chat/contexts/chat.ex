defmodule LlmChat.Contexts.Chat do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.{Chat, Message, User}

  def create(attrs) do
    %Chat{} |> Chat.changeset(attrs) |> insert!()
  end

  def validate(chat_id) do
    case Chat |> get(chat_id) do
      nil -> {:error}
      chat -> {:ok, chat}
    end
  end

  def touch(chat_id) do
    Chat
    |> get(chat_id)
    |> Chat.changeset(%{})
    |> Ecto.Changeset.put_change(:updated_at, DateTime.utc_now(:second))
    |> update!()
  end

  def user_msg(chat_id, turn_number, content) do
    msg(chat_id, turn_number, "user", content)
  end

  def assistant_msg(chat_id, turn_number, content) do
    msg(chat_id, turn_number, "assistant", content)
  end

  defp msg(chat_id, turn_number, role, content) do
    %{chat_id: chat_id, turn_number: turn_number, role: role, content: content}
  end

  def add_message!(chat_id, content, role, turn_number) do
    %Message{}
    |> Message.changeset(%{
      content: content,
      chat_id: chat_id,
      role: role,
      turn_number: turn_number
    })
    |> insert!()
  end

  def details(chat_id) do
    chat = Chat |> get(chat_id)

    messages =
      from(m in Message,
        where: m.chat_id == ^chat_id,
        order_by: [asc: m.inserted_at]
      )
      |> all()

    %{chat: chat, messages: messages}
  end

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
end
