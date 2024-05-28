defmodule LlmChatWeb.Router do
  use LlmChatWeb, :router

  import LlmChatWeb.UserGauth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {LlmChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  scope "/", LlmChatWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/gauth", PageController, :gauth
  end

  scope "/", LlmChatWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/auth/google/callback", GauthController, :callback
  end

  scope "/", LlmChatWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/logout", GauthController, :logout

    live_session :authenticated,
      on_mount: [{LlmChatWeb.UserGauth, :ensure_authenticated}] do
      live "/chats", ChatsLive, :index
      live "/chats/:id", ChatsLive, :show
    end
  end

  if Application.compile_env(:llm_chat, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/admin" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: LlmChatWeb.Telemetry
    end
  end
end
