defmodule LlmChat.Contexts.Conversation do
  @moduledoc false
  import Ecto.Query
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.{Chat, Message}

  def current_path(chat_id) do
    Chat |> get!(chat_id) |> Map.get(:ui_path)
  end

  def update_current_path!(chat_id, path) do
    Chat |> get!(chat_id) |> Chat.changeset(%{ui_path: path}) |> update!()
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

  def parent_path(path) do
    case :binary.split(path, ".", [:global, :trim]) do
      [] -> ""
      parts -> parts |> Enum.reverse() |> tl |> Enum.reverse() |> Enum.join(".")
    end
  end

  def msg_path(parent_path, turn_number) when is_nil(parent_path) do
    "#{turn_number}"
  end

  def msg_path(parent_path, turn_number) do
    "#{parent_path}.#{turn_number}"
  end
end
