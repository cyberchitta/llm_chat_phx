defmodule LlmChatWeb.GauthController do
  use LlmChatWeb, :controller

  require Logger
  alias LlmChatWeb.UserGauth

  def callback(conn, %{"code" => code}) do
    {:ok, token} = ElixirAuthGoogle.get_token(code, conn)
    {:ok, profile} = ElixirAuthGoogle.get_user_profile(token.access_token)
    user = LlmChat.Contexts.User.upsert!(profile)
    conn |> UserGauth.log_in_user(user) |> render(:welcome, user: user)
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserGauth.log_out_user()
  end
end
