defmodule LlmChatWeb.UserGauth do
  @moduledoc false
  use LlmChatWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias LlmChat.Contexts.User

  # 5 days in seconds
  @max_age 60 * 60 * 24 * 5
  @session_error "You must be logged in with a current session to access this page."

  def max_age(), do: @max_age

  def gauth_url() do
    LlmChatWeb.Endpoint.url() |> ElixirAuthGoogle.generate_oauth_url()
  end

  def login_url(), do: ~p"/login"

  def fetch_current_user(conn, _opts) do
    user_email = get_session(conn, :user_email)
    conn |> assign(:user_email, user_email)
  end

  def validate_user_session(conn, _opts) do
    with email when not is_nil(email) <- get_session(conn, :user_email),
         user when not is_nil(user) <- User.get_by_email(email) do
      conn |> assign(:user, user)
    else
      _ -> conn |> plug_force_login()
    end
  end

  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:user_email],
      do: conn |> redirect(to: signed_in_path(conn)) |> halt(),
      else: conn
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:user_email], do: conn, else: conn |> plug_force_login()
  end

  def log_in_user(conn, user) do
    conn |> renew_session() |> start_session(user.email)
  end

  def log_out_user(conn) do
    if live_socket_id = get_session(conn, :live_socket_id) do
      LlmChatWeb.Endpoint.broadcast(live_socket_id, "disconnect", %{})
    end

    conn |> renew_session() |> redirect(to: ~p"/")
  end

  def on_mount(:mount_user, _params, session, socket) do
    {:cont, mount_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = mount_user(socket, session)

    if socket.assigns[:user_email] do
      {:cont, socket}
    else
      {:halt,
       socket
       |> Phoenix.LiveView.put_flash(:error, @session_error)
       |> Phoenix.LiveView.redirect(to: login_url())}
    end
  end

  def on_mount(:redirect_if_user_is_authenticated, _params, session, socket) do
    socket = mount_user(socket, session)

    if socket.assigns[:user_email] do
      {:halt, Phoenix.LiveView.redirect(socket, to: signed_in_path(socket))}
    else
      {:cont, socket}
    end
  end

  defp mount_user(socket, session) do
    user_email = session["user_email"]

    socket
    |> Phoenix.Component.assign(:user_email, user_email)
    |> Phoenix.Component.assign_new(:user, fn ->
      if user_email do
        User.get_by_email(user_email)
      end
    end)
  end

  defp plug_force_login(conn) do
    conn
    |> put_flash(:error, @session_error)
    |> renew_session()
    |> maybe_store_return_to()
    |> redirect(to: login_url())
    |> halt()
  end

  defp renew_session(conn) do
    delete_csrf_token()
    conn |> configure_session(renew: true) |> clear_session()
  end

  defp start_session(conn, token) do
    conn
    |> put_session(:user_email, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end
