import Config
import Dotenvy

dir = System.get_env("RELEASE_ROOT") || "envs/"

source!([
  "#{dir}.#{config_env()}.env",
  "#{dir}.#{config_env()}.local.env",
  System.get_env()
])

if System.get_env("PHX_SERVER") do
  config :llm_chat, LlmChatWeb.Endpoint, server: true
end

config :llm_chat, LlmChatWeb.Endpoint,
  secret_key_base: env!("SECRET_KEY_BASE", :string),
  http: [
    ip:
      env!("PHX_IP", fn ip ->
        ip
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.map(&String.to_integer/1)
        |> List.to_tuple()
      end),
    port: env!("PHX_PORT", :integer)
  ]

config :llm_chat, LlmChat.RepoPostgres,
  url:
    (
      pg_db =
        if config_env() == :prod,
          do: env!("POSTGRES_DB"),
          else: Application.fetch_env!(:llm_chat, LlmChat.RepoPostgres)[:database]

      pg_user = env!("POSTGRES_USER")
      pg_passwd = env!("POSTGRES_PASSWORD")
      pg_host = env!("POSTGRES_HOST")
      pg_port = env!("POSTGRES_PORT")
      "postgres://#{pg_user}:#{pg_passwd}@#{pg_host}:#{pg_port}/#{pg_db}"
    ),
  ssl: false

config :llm_chat,
  openai_api_key: env!("OPENAI_API_KEY"),
  s3_bucket_name: env!("S3_BUCKET_NAME")

config :elixir_auth_google,
  client_id: env!("GOOGLE_CLIENT_ID"),
  client_secret: env!("GOOGLE_CLIENT_SECRET")

config :ex_aws,
  json_codec: Jason,
  access_key_id: env!("AWS_ACCESS_KEY_ID"),
  secret_access_key: env!("AWS_SECRET_ACCESS_KEY")

config :ex_aws, :s3,
  scheme: env!("S3_SCHEME"),
  host: env!("S3_HOST"),
  port: env!("S3_PORT"),
  region: env!("S3_REGION")

if config_env() == :prod do
  host = env!("PHX_HOST", :string, "example.com")

  config :llm_chat, :dns_cluster_query, env!("DNS_CLUSTER_QUERY", :string?)

  config :llm_chat, LlmChatWeb.Endpoint, url: [host: host, port: 443, scheme: "https"]
end

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to your endpoint configuration:
#
#     config :llm_chat, LlmChatWeb.Endpoint,
#       https: [
#         ...,
#         port: 443,
#         cipher_suite: :strong,
#         keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#         certfile: System.get_env("SOME_APP_SSL_CERT_PATH")
#       ]
#
# The `cipher_suite` is set to `:strong` to support only the
# latest and more secure SSL ciphers. This means old browsers
# and clients may not be supported. You can set it to
# `:compatible` for wider support.
#
# `:keyfile` and `:certfile` expect an absolute path to the key
# and cert in disk or a relative path inside priv, for example
# "priv/ssl/server.key". For all supported SSL configuration
# options, see https://hexdocs.pm/plug/Plug.SSL.html#configure/1
#
# We also recommend setting `force_ssl` in your config/prod.exs,
# ensuring no data is ever sent via http, always redirecting to https:
#
#     config :llm_chat, LlmChatWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.
