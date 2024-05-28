import Config

config :llm_chat, LlmChatWeb.Endpoint,
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:llm_chat, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:llm_chat, ~w(--watch)]}
  ]

config :llm_chat, LlmChatWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"lib/llm_chat_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :llm_chat, LlmChat.RepoPostgres,
  database: "llm_chat_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :llm_chat, LlmChat.RepoXandra,
  sync_connect: 5000,
  log: :info,
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :llm_chat, dev_routes: true
config :logger, :console, format: "[$level] $message\n"
config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime
config :phoenix_live_view, :debug_heex_annotations, true
