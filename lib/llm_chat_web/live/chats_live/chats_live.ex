defmodule LlmChatWeb.ChatsLive do
  alias LlmChatWeb.UserGauth
  use LlmChatWeb, :live_view
  require Logger

  import LlmChatWeb.Live.ChatsLive.Html

  alias LlmChat.Contexts.Chat
  alias LlmChat.Files
  alias LlmChatWeb.UiState

  def mount(%{"id" => chat_id}, %{"user_email" => user_email}, socket) do
    {:ok,
     socket
     |> assign(UiState.index(user_email, chat_id))
     |> enable_attachments()
     |> enable_gauth()}
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
    sidebar_toggle(socket)
  end

  def handle_event("to_index", _, socket) do
    sidebar_to_index(socket)
  end

  def handle_event("rename_chat", %{"id" => _, "new_name" => _} = params, socket) do
    sidebar_rename_chat(params, socket)
  end

  def handle_event("delete_chat", %{"id" => _} = params, socket) do
    sidebar_delete_chat(params, socket)
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("submit", %{"prompt-textarea" => prompt}, socket) do
    handle_uploads(socket) |> handle_submit(prompt)
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachments, ref)}
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

    user_msg = Chat.add_message!(user)
    asst_msg = Chat.add_message!(asst |> Map.put(:parent_id, user_msg.id))
    Chat.update_ui_path!(user.chat_id, asst_msg.path)
    next_messages = main.messages ++ [user_msg, asst_msg]
    next_main = %{main | messages: next_messages}
    {:noreply, assign(socket, main: next_main |> UiState.with_streaming())}
  end

  def handle_info({:submit_prompt, prompt}, socket) do
    handle_submit_existing_chat(prompt, [], socket)
  end

  def handle_info(message, socket) do
    Logger.error("Unmatched message: #{inspect(message)}")
    {:noreply, socket}
  end

  defp handle_submit({attachments, socket}, prompt) do
    if socket.assigns.live_action == :index do
      handle_submit_new_chat(prompt, socket)
    else
      handle_submit_existing_chat(prompt, attachments, socket)
    end
  end

  defp handle_submit_new_chat(prompt, socket) do
    user = socket.assigns.user
    chat = Chat.create(%{name: "NewChat", user_id: user.id})
    {:noreply, socket |> push_navigate(to: ~p"/chats/#{chat.id}?prompt=#{URI.encode(prompt)}")}
  end

  defp handle_submit_existing_chat(prompt, attachments, socket) do
    main = socket.assigns.main
    messages = main.messages

    chat_id = main.chat.id
    turn_number = length(messages) + 1
    parent_id = if Enum.empty?(messages), do: nil, else: List.last(messages).id
    msg_u = Chat.msg(chat_id, parent_id, turn_number)
    msg_a = Chat.msg(chat_id, nil, turn_number + 1)

    streaming = %{
      user: msg_u |> Chat.with_content(prompt, attachments) |> Chat.to_user(),
      assistant: msg_a |> Chat.with_content() |> Chat.to_assistant(),
      cancel_pid: nil
    }

    liveview_pid = self()

    Task.Supervisor.start_child(LlmChat.TaskSupervisor, fn ->
      stream = LlmChat.Llm.Chat.initiate_stream(prompt, attachments)
      send(liveview_pid, {:cancel_pid, stream.task_pid})
      LlmChat.Llm.Chat.process_stream(liveview_pid, stream)
    end)

    {:noreply, socket |> assign(main: main |> UiState.with_streaming(streaming))}
  end

  defp handle_uploads(socket) do
    if socket.assigns.live_action != :index do
      uploads =
        consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
          content_type = entry.client_type || Files.MimeTypes.guess(entry.client_name)
          upload(path, content_type)
        end)
        |> Enum.reject(&is_nil/1)

      uploaded_fns = Enum.map(uploads, & &1.filename)
      upd_socket = update(socket, :uploaded_files, &(&1 ++ uploaded_fns))
      {uploads, upd_socket}
    else
      {[], socket}
    end
  end

  defp enable_attachments(socket) do
    socket
    |> assign(:uploaded_files, [])
    |> allow_upload(:attachments, accept: ~w(.txt .md .jpg .jpeg .png .gif .webp), max_entries: 2)
  end

  defp enable_gauth(socket) do
    socket |> assign(oauth_google_url: UserGauth.gauth_url())
  end

  def upload(path, content_type) do
    filename = Path.basename(path)
    unique_filename = "#{Ecto.UUID.generate()}_#{filename}"

    case Files.S3Uploader.upload(path, unique_filename, content_type) do
      {:ok, upload} -> {:ok, upload}
      {:error, _} -> {:ok, nil}
    end
  end

  def sidebar_toggle(socket) do
    {:noreply, update(socket, :sidebar_open, fn sidebar_open -> !sidebar_open end)}
  end

  def sidebar_to_index(socket) do
    if socket.assigns.live_action != :index do
      {:noreply, push_navigate(socket, to: ~p"/chats")}
    else
      {:noreply, socket}
    end
  end

  def sidebar_rename_chat(%{"id" => chat_id, "new_name" => new_name}, socket) do
    Chat.rename(chat_id, new_name)
    {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
  end

  def sidebar_delete_chat(%{"id" => chat_id}, socket) do
    Chat.delete(chat_id)

    if get_in(socket.assigns, [:main, :chat, :id]) == chat_id do
      {:noreply, socket |> push_navigate(to: ~p"/chats")}
    else
      {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
    end
  end
end
