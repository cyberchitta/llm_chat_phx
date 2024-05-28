defmodule LlmChat.RepoPostgres do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :llm_chat,
    adapter: Ecto.Adapters.Postgres
end
