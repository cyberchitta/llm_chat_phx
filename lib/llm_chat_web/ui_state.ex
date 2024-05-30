defmodule LlmChatWeb.UiState do
  @moduledoc false
  alias LlmChat.Contexts.{Chat, User, Suggestion}

  def index(user_email) do
    suggestions = Suggestion.get_default()
    prompt = Enum.random(suggestions)

    %{
      sidebar: sidebar(user_email),
      main: %{suggestions: suggestions, uistate: uistate(prompt)},
      sidebar_open: true
    }
  end

  def index(user_email, chat_id) do
    chat = Chat.details(chat_id)

    %{
      sidebar: sidebar(user_email),
      main: Map.put(chat, :uistate, uistate("")),
      sidebar_open: true
    }
  end

  defp sidebar(user_email) do
    if is_nil(user_email) do
      %{periods: [], user: nil}
    else
      %{periods: Chat.list_by_period(user_email), user: User.get_by_email(user_email)}
    end
  end

  defp uistate(prompt) do
    %{streaming: nil, prompt: prompt}
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
end
