defmodule LlmChatWeb.UiState do
  @moduledoc false
  alias LlmChat.Contexts.{Chat, User, Suggestion}

  def index(user_email) do
    suggestions = Suggestion.get_default()
    prompt = Enum.random(suggestions)
    index(user_email, %{suggestions: suggestions, uistate: uistate(prompt)})
  end

  def index(user_email, chat_id) when is_binary(chat_id) do
    index(user_email, Chat.details(chat_id) |> Map.put(:uistate, uistate("")))
  end

  def index(user_email, main = %{}) do
    %{
      main: main,
      sidebar: sidebar(user_email),
      sidebar_open: true,
      user: User.get_by_email(user_email)
    }
  end

  def sidebar(user_email) do
    if is_nil(user_email), do: %{periods: []}, else: %{periods: Chat.list_by_period(user_email)}
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
