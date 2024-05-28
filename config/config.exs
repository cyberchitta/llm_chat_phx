import Config

config :llm_chat, LlmChatWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: LlmChatWeb.ErrorHTML, json: LlmChatWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: LlmChat.PubSub,
  live_view: [signing_salt: "zs6SQ7ka"]

config :llm_chat,
  generators: [timestamp_type: :utc_datetime]

config :llm_chat, ecto_repos: [LlmChat.RepoPostgres]

config :llm_chat, LlmChat.RepoPostgres, priv: "priv/repo/postgres"

config :llm_chat, LlmChat.RepoXandra,
  migration_primary_key: [name: :id, type: :uuid],
  nodes: ["scylladb"],
  keyspace: "llm_chat",
  priv: "priv/repo/xandra"

config :esbuild,
  version: "0.17.11",
  llm_chat: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.4.0",
  llm_chat: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
