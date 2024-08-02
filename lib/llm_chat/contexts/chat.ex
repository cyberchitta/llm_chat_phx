defmodule LlmChat.Contexts.Chat do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Contexts.Message
  alias LlmChat.Schemas.{Chat, User}

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

  def details(chat_id, ui_path) do
    %{
      chat: Chat |> get(chat_id),
      messages:
        chat_id
        |> Message.get_ui_thread(ui_path)
        |> Enum.map(&Map.put(&1, :sibling_info, Message.get_sibling_info(chat_id, &1)))
    }
  end

  def update_max_turn_number!(chat_id, turn_number) do
    from(c in Chat, where: c.id == ^chat_id)
    |> Ecto.Query.update(
      set: [max_turn_number: fragment("GREATEST(max_turn_number, ?)", ^turn_number)]
    )
    |> update_all([])
  end
end
