defmodule LlmChat.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      LlmChat.RepoPostgres,
      LlmChatWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:llm_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LlmChat.PubSub},
      LlmChatWeb.Endpoint,
      {Task.Supervisor, name: LlmChat.TaskSupervisor}
    ]

    opts = [strategy: :one_for_one, name: LlmChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    LlmChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
