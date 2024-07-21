defmodule LlmChatWeb.GauthController do
  use LlmChatWeb, :controller

  require Logger
  alias LlmChatWeb.UserGauth

  def callback(conn, %{"code" => code}) do
    with {:ok, token} <- ElixirAuthGoogle.get_token(code, conn),
         {:ok, profile} <- ElixirAuthGoogle.get_user_profile(token.access_token),
         {:ok, user} <- LlmChat.Contexts.User.upsert(profile) do
      conn |> UserGauth.log_in_user(user) |> render(:welcome, user: user)
    else
      {:error, reason} ->
        Logger.error("Google Auth error: #{inspect(reason)}")
        handle_auth_error(conn, "Unable to complete authentication. Please try again later.")
    end
  end

  def callback(conn, _params) do
    Logger.warn("Invalid Google Auth callback parameters")
    handle_auth_error(conn, "Invalid authentication response. Please try again.")
  end

  def logout(conn, _params) do
    conn |> put_flash(:info, "Logged out successfully.") |> UserGauth.log_out_user()
  end

  defp handle_auth_error(conn, message) do
    conn |> put_flash(:error, message) |> redirect(to: ~p"/login")
  end
end
