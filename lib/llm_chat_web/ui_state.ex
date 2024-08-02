defmodule LlmChatWeb.UiState do
  @moduledoc false
  alias LlmChat.Contexts.{Chat, Conversation, User, Suggestion}

  def index(user_email) do
    suggestions = Suggestion.get_default()
    suggestion = Enum.random(suggestions)
    index(user_email, %{suggestions: suggestions, uistate: uistate(nil, suggestion)})
  end

  def index(user_email, chat_id) when is_binary(chat_id) do
    index(user_email, chat_id, Conversation.current_path(chat_id))
  end

  def index(user_email, %{} = main) do
    %{
      main: main,
      sidebar: sidebar(user_email),
      sidebar_open: true,
      user: User.get_by_email(user_email)
    }
  end

  def index(user_email, chat_id, ui_path) when is_binary(chat_id) do
    main = Chat.details(chat_id, ui_path)
    index(user_email, main |> Map.put(:uistate, uistate(ui_path, "")))
  end

  def sidebar(user_email) do
    if is_nil(user_email), do: %{periods: []}, else: %{periods: Chat.list_by_period(user_email)}
  end

  defp uistate(ui_path, suggestion) do
    %{streaming: nil, ui_path: ui_path, suggestion: suggestion, edit_msg_id: ""}
  end

  def with_streaming(main, streaming \\ nil) do
    %{main | uistate: %{main.uistate | streaming: streaming}}
  end

  def with_cancel_pid(main, pid \\ nil) do
    %{main | uistate: %{main.uistate | streaming: %{main.uistate.streaming | cancel_pid: pid}}}
  end

  def with_chunk(streaming, chunk) do
    assistant = streaming.assistant
    content = assistant.content
    %{streaming | assistant: %{assistant | content: content <> chunk}}
  end

  def with_edit(main, edit_msg_id) do
    %{main | uistate: %{main.uistate | edit_msg_id: edit_msg_id}}
  end

  def with_ui_path(main, ui_path) do
    main |> Map.merge(Chat.details(main.chat.id, ui_path))
  end
end
