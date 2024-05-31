defmodule LlmChatWeb.ChatsLive do
  alias LlmChatWeb.UserGauth
  use LlmChatWeb, :live_view
  require Logger

  import LlmChatWeb.Live.ChatsLive.Html

  alias LlmChat.Contexts.Chat
  alias LlmChatWeb.UiState

  def mount(%{"id" => chat_id}, %{"user_email" => user_email}, socket) do
    {:ok, socket |> assign(UiState.index(user_email, chat_id)) |> enable_gauth()}
  end

  def mount(_params, %{"user_email" => user_email}, socket) do
    {:ok, socket |> assign(UiState.index(user_email)) |> enable_gauth()}
  end

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(UiState.index(nil)) |> enable_gauth()}
  end

  def handle_params(%{"id" => chat_id, "prompt" => prompt}, _uri, socket) do
    send(self(), {:submit_prompt, URI.decode(prompt)})
    {:noreply, socket |> push_patch(to: ~p"/chats/#{chat_id}", replace: true)}
  end

  def handle_params(_params, _uri, socket) do
    {:noreply, socket}
  end

  def handle_event("toggle_sidebar", _, socket) do
    {:noreply, update(socket, :sidebar_open, fn sidebar_open -> !sidebar_open end)}
  end

  def handle_event("to_index", _, socket) do
    if socket.assigns.live_action != :index do
      {:noreply, push_navigate(socket, to: ~p"/chats")}
    else
      {:noreply, socket}
    end
  end

  def handle_event("rename_chat", %{"id" => chat_id, "new_name" => new_name}, socket) do
    Chat.rename(chat_id, new_name)
    {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
  end

  def handle_event("delete_chat", %{"id" => chat_id}, socket) do
    Chat.delete(chat_id)

    if socket.assigns.main.chat.id == chat_id do
      {:noreply, socket |> push_navigate(to: ~p"/chats")}
    else
      {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
    end
  end

  def handle_event("submit", %{"prompt-textarea" => prompt}, socket) do
    if Map.get(socket.assigns.main, :chat) do
      handle_submit_existing_chat(prompt, socket)
    else
      handle_submit_new_chat(prompt, socket)
    end
  end

  def handle_event("cancel", _, socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming

    if streaming && streaming.cancel_pid do
      LlmChat.Llm.Chat.cancel_stream(streaming.cancel_pid)
      {:noreply, assign(socket, main: main |> UiState.with_streaming())}
    else
      {:noreply, socket}
    end
  end

  def handle_info({:cancel_pid, pid}, socket) do
    main = socket.assigns.main
    {:noreply, assign(socket, main: main |> UiState.with_cancel_pid(pid))}
  end

  def handle_info({:next_chunk, chunk}, socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming |> UiState.with_chunk(chunk)
    {:noreply, assign(socket, main: main |> UiState.with_streaming(streaming))}
  end

  def handle_info(:end_of_stream, socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming

    user = streaming.user
    asst = streaming.assistant
    user_record = Chat.add_message!(user.chat_id, user.content, user.role, user.turn_number)
    asst_record = Chat.add_message!(asst.chat_id, asst.content, asst.role, asst.turn_number)
    Chat.touch(user.chat_id)
    next_messages = main.messages ++ [user_record, asst_record]
    next_main = %{main | messages: next_messages}
    {:noreply, assign(socket, main: next_main |> UiState.with_streaming())}
  end

  def handle_info({:submit_prompt, prompt}, socket) do
    handle_submit_existing_chat(prompt, socket)
  end

  def handle_info(message, socket) do
    Logger.error("Unmatched message: #{inspect(message)}")
    {:noreply, socket}
  end

  defp handle_submit_new_chat(prompt, socket) do
    user = socket.assigns.user
    chat = Chat.create(%{name: "NewChat", user_id: user.id})
    {:noreply, socket |> push_navigate(to: ~p"/chats/#{chat.id}?prompt=#{URI.encode(prompt)}")}
  end

  defp handle_submit_existing_chat(prompt, socket) do
    main = socket.assigns.main
    chat_id = main.chat.id
    turn_number = length(main.messages) + 1

    streaming = %{
      user: Chat.user_msg(chat_id, turn_number, prompt) |> Map.put(:id, nil),
      assistant: Chat.assistant_msg(chat_id, turn_number + 1, "") |> Map.put(:id, nil),
      cancel_pid: nil
    }

    liveview_pid = self()

    Task.Supervisor.start_child(LlmChat.TaskSupervisor, fn ->
      stream = LlmChat.Llm.Chat.initiate_stream(prompt)
      send(liveview_pid, {:cancel_pid, stream.task_pid})
      LlmChat.Llm.Chat.process_stream(liveview_pid, stream)
    end)

    {:noreply, socket |> assign(main: main |> UiState.with_streaming(streaming))}
  end

  defp enable_gauth(socket) do
    socket |> assign(oauth_google_url: UserGauth.gauth_url())
  end
end
