import Config

config :llm_chat, LlmChatWeb.Endpoint, server: false

config :logger, level: :warning
config :phoenix, :plug_init_mode, :runtime

config :llm_chat, LlmChat.RepoPostgres,
  database: "llm_chat_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :elixir_auth_google,
  httpoison_mock: true
