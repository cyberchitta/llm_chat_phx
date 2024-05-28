import Config

config :llm_chat, LlmChatWeb.Endpoint, cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :llm_chat, LlmChat.RepoPostgres, pool_size: 2
