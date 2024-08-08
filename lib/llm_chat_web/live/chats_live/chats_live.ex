defmodule LlmChatWeb.ChatsLive do
  alias LlmChatWeb.UserGauth
  use LlmChatWeb, :live_view
  require Logger

  import LlmChatWeb.Live.ChatsLive.Html

  alias LlmChat.Contexts.{Chat, Message, LlmPreset, Conversation, Feedback}
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

  def handle_event("rename_chat", params, socket) do
    sidebar_rename_chat(params, socket)
  end

  def handle_event("delete_chat", params, socket) do
    sidebar_delete_chat(params, socket)
  end

  def handle_event("validate", params, socket) do
    chat_validate(params, socket)
  end

  def handle_event("submit", %{"prompt-textarea" => prompt}, socket) do
    chat_uploads(socket) |> chat_submit(prompt)
  end

  def handle_event("cancel", _, socket) do
    streamer_cancel(socket)
  end

  def handle_event("cancel-upload", params, socket) do
    chat_cancel_upload(params, socket)
  end

  def handle_event("edit_message", params, socket) do
    useredit_begin(params, socket)
  end

  def handle_event("cancel_edit", _, socket) do
    useredit_cancel(socket)
  end

  def handle_event("save_edit", params, socket) do
    useredit_save(params, socket)
  end

  def handle_event("navigate_sibling", params, socket) do
    msg_navigator_sibling(params, socket)
  end

  def handle_event("set_feedback", params, socket) do
    asst_ctrls_feedback(params, socket)
  end

  def handle_event("narrate", params, socket) do
    asst_ctrls_narrate(params, socket)
  end

  def handle_event("whisper", params, socket) do
    input_whisper(params, socket)
  end

  def handle_event("change_preset", params, socket) do
    preset_dd(params, socket)
  end

  def handle_info({:cancel_pid, pid}, socket) do
    streamer_with_cancel_pid(pid, socket)
  end

  def handle_info({:next_chunk, chunk}, socket) do
    streamer_next_chunk(chunk, socket)
  end

  def handle_info(:end_of_stream, socket) do
    streamer_end_of_stream(socket)
  end

  def handle_info({:submit_prompt, prompt}, socket) do
    chat_submit_existing(prompt, [], socket)
  end

  def handle_info({:audio_ready, message_id, audio_content}, socket) do
    asst_ctrls_narrate_ready(message_id, audio_content, socket)
  end

  def handle_info({:audio_error, message_id, reason}, socket) do
    asst_ctrls_narrate_error(message_id, reason, socket)
  end

  def handle_info({:transcript_ready, message_id, transcript}, socket) do
    input_whisper_ready(message_id, transcript, socket)
  end

  def handle_info({:transcript_error, message_id, reason}, socket) do
    input_whisper_error(message_id, reason, socket)
  end

  def handle_info(message, socket) do
    Logger.error("Unmatched message: #{inspect(message)}")
    {:noreply, socket}
  end

  defp enable_attachments(socket) do
    socket
    |> assign(:uploaded_files, [])
    |> allow_upload(:attachments, accept: ~w(.txt .md .jpg .jpeg .png .gif .webp), max_entries: 2)
  end

  defp enable_gauth(socket) do
    socket |> assign(oauth_google_url: UserGauth.gauth_url())
  end

  def preset_dd(%{"preset_name" => preset_name}, socket) do
    main = socket.assigns.main
    chat = main.chat

    upd_main =
      if chat, do: %{main | chat: LlmPreset.update_preset!(chat.id, preset_name)}, else: main

    {:noreply, assign(socket, :main, upd_main |> UiState.with_selected_preset(preset_name))}
  end

  defp chat_validate(_, socket) do
    {:noreply, socket}
  end

  defp chat_submit({attachments, socket}, prompt) do
    if socket.assigns.live_action == :index do
      chat_submit_new(prompt, socket)
    else
      chat_submit_existing(prompt, attachments, socket)
    end
  end

  defp chat_submit_new(prompt, socket) do
    user = socket.assigns.user
    preset = socket.assigns.main.uistate.sel_preset
    chat = Chat.create(%{name: "NewChat", user_id: user.id, preset_name: preset.name})
    {:noreply, socket |> push_navigate(to: ~p"/chats/#{chat.id}?prompt=#{URI.encode(prompt)}")}
  end

  defp chat_submit_existing(prompt, attachments, socket) do
    main = socket.assigns.main
    streaming = chat_stream_state(main, prompt, attachments)
    liveview_pid = self()
    preset = main.chat.preset

    Task.Supervisor.start_child(LlmChat.TaskSupervisor, fn ->
      stream = LlmChat.Llm.Chat.initiate_stream(prompt, attachments, preset)
      send(liveview_pid, {:cancel_pid, stream.task_pid})
      LlmChat.Llm.Chat.process_stream(liveview_pid, stream)
    end)

    {:noreply, socket |> assign(main: main |> UiState.with_streaming(streaming))}
  end

  defp chat_stream_state(main, prompt, attachments) do
    chat_id = main.chat.id
    messages = main.messages
    turn_number = main.chat.max_turn_number + 1

    parent_id = if Enum.empty?(messages), do: nil, else: List.last(messages).id
    msg_u = Message.msg(chat_id, parent_id, turn_number)
    msg_a = Message.msg(chat_id, nil, turn_number + 1)

    %{
      user: msg_u |> Message.with_content(prompt, attachments) |> Message.to_user(),
      assistant: msg_a |> Message.with_content() |> Message.to_assistant(),
      cancel_pid: nil
    }
  end

  defp chat_cancel_upload(%{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :attachments, ref)}
  end

  defp chat_uploads(socket) do
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

  defp useredit_begin(%{"id" => message_id}, socket) do
    {:noreply, assign(socket, main: UiState.with_edit(socket.assigns.main, message_id))}
  end

  defp useredit_cancel(socket) do
    {:noreply, assign(socket, main: UiState.with_edit(socket.assigns.main, ""))}
  end

  defp useredit_save(%{"edit-textarea" => content}, socket) do
    main = socket.assigns.main
    message_id = main.uistate.edit_msg_id
    message = Enum.find(main.messages, &(&1.id == message_id))
    parent_path = Conversation.parent_path(message.path)
    updated_main = main |> UiState.with_ui_path(parent_path)
    attachments = message.attachments
    upd_socket = socket |> assign(main: updated_main)
    {attachments, upd_socket} |> chat_submit(content)
  end

  def asst_ctrls_feedback(%{"id" => msg_id, "feedback" => feedback_type}, socket) do
    case Feedback.get_feedback(msg_id) do
      nil -> {:ok, _} = Feedback.upsert(%{message_id: msg_id, type: feedback_type})
      %{type: ^feedback_type} -> Feedback.delete_feedback(msg_id)
      _ -> {:ok, _} = Feedback.upsert(%{message_id: msg_id, type: feedback_type})
    end

    updated_messages =
      Enum.map(socket.assigns.main.messages, fn m ->
        if m.id == msg_id, do: %{m | feedback: Feedback.get_feedback(msg_id)}, else: m
      end)

    {:noreply, assign(socket, main: %{socket.assigns.main | messages: updated_messages})}
  end

  defp asst_ctrls_narrate(%{"message_id" => message_id}, socket) do
    message = Enum.find(socket.assigns.main.messages, &(&1.id == message_id))
    LlmChat.Llm.Audio.initiate_tts(self(), message_id, message.content)
    {:noreply, socket}
  end

  defp asst_ctrls_narrate_ready(message_id, audio_content, socket) do
    narr_json = %{audio_content: Base.encode64(audio_content), message_id: message_id}
    {:noreply, socket |> push_event("audio_ready", narr_json)}
  end

  defp asst_ctrls_narrate_error(message_id, reason, socket) do
    {:noreply, socket |> push_event("audio_error", %{message_id: message_id, reason: reason})}
  end

  def input_whisper(
        %{"audio_data" => audio_data, "message_id" => message_id, "content_type" => content_type},
        socket
      ) do
    LlmChat.Llm.Audio.initiate_transcription(self(), message_id, audio_data, content_type)
    {:noreply, socket}
  end

  def input_whisper_ready(message_id, transcript, socket) do
    {:noreply,
     push_event(socket, "transcription_ready", %{message_id: message_id, text: transcript})}
  end

  def input_whisper_error(message_id, reason, socket) do
    {:noreply,
     socket
     |> put_flash(:error, "Transcription failed: #{inspect(reason)}")
     |> push_event("transcription_error", %{message_id: message_id, reason: inspect(reason)})}
  end

  defp msg_navigator_sibling(%{"direction" => direction, "message-id" => message_id}, socket) do
    main = socket.assigns.main
    message = Enum.find(main.messages, &(&1.id == message_id))
    sibling_info = message.sibling_info

    sib_idx =
      case direction do
        "prev" -> max(1, sibling_info.current - 1)
        "next" -> min(sibling_info.total, sibling_info.current + 1)
      end

    sibling_id = Enum.at(sibling_info.sibling_ids, sib_idx - 1)
    path = Conversation.get_leftmost_path(main.chat.id, sibling_id)
    {:noreply, assign(socket, main: main |> UiState.with_ui_path(path))}
  end

  defp streamer_cancel(socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming

    if streaming && streaming.cancel_pid do
      LlmChat.Llm.Chat.cancel_stream(streaming.cancel_pid)
      {:noreply, assign(socket, main: main |> UiState.with_streaming())}
    else
      {:noreply, socket}
    end
  end

  defp streamer_with_cancel_pid(pid, socket) do
    main = socket.assigns.main
    {:noreply, assign(socket, main: main |> UiState.with_cancel_pid(pid))}
  end

  defp streamer_next_chunk(chunk, socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming |> UiState.with_chunk(chunk)
    {:noreply, assign(socket, main: main |> UiState.with_streaming(streaming))}
  end

  defp streamer_end_of_stream(socket) do
    main = socket.assigns.main
    streaming = main.uistate.streaming
    user = streaming.user
    asst = streaming.assistant

    user_msg = Message.add_message!(user)
    asst_msg = Message.add_message!(asst |> Map.put(:parent_id, user_msg.id))
    Chat.update_max_turn_number!(user.chat_id, asst_msg.turn_number)
    Conversation.update_current_path!(user.chat_id, asst_msg.path)
    next_messages = main.messages ++ [user_msg, asst_msg]
    next_main = %{main | messages: next_messages}
    {:noreply, assign(socket, main: next_main |> UiState.with_streaming())}
  end

  defp sidebar_toggle(socket) do
    {:noreply, update(socket, :sidebar_open, fn sidebar_open -> !sidebar_open end)}
  end

  defp sidebar_to_index(socket) do
    if socket.assigns.live_action != :index do
      {:noreply, push_navigate(socket, to: ~p"/chats")}
    else
      {:noreply, socket}
    end
  end

  defp sidebar_rename_chat(%{"id" => chat_id, "new_name" => new_name}, socket) do
    Chat.rename(chat_id, new_name)
    {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
  end

  defp sidebar_delete_chat(%{"id" => chat_id}, socket) do
    chat = get_in(socket.assigns, [:main, :chat])
    Chat.delete(chat_id)

    if !is_nil(chat) && chat.id == chat_id do
      {:noreply, socket |> push_navigate(to: ~p"/chats")}
    else
      {:noreply, assign(socket, :sidebar, UiState.sidebar(socket.assigns.user_email))}
    end
  end

  def upload(path, content_type) do
    filename = Path.basename(path)
    unique_filename = "#{Ecto.UUID.generate()}_#{filename}"

    case Files.S3Uploader.upload(path, unique_filename, content_type) do
      {:ok, upload} -> {:ok, upload}
      {:error, _} -> {:ok, nil}
    end
  end
end
