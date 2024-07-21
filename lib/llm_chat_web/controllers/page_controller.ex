# lib/llm_chat_web/controllers/page_controller.ex
defmodule LlmChatWeb.PageController do
  alias LlmChatWeb.UserGauth
  use LlmChatWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def login(conn, _params) do
    render(conn, "login.html")
  end

  def gauth(conn, _params) do
    redirect(conn, external: UserGauth.gauth_url())
  end
end
