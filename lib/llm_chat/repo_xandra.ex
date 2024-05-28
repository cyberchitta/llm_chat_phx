defmodule LlmChat.RepoXandra do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :llm_chat,
    adapter: Exandra
end
