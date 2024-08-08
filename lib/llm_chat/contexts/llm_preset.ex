defmodule LlmChat.Contexts.LlmPreset do
  @moduledoc false
  import LlmChat.RepoPostgres
  alias LlmChat.Schemas.Chat

  @presets [
    %{
      name: "gpt4o",
      provider: %{
        "name" => "OpenAI",
        "base_url" => "https://api.openai.com/v1"
      },
      model: "gpt-4o",
      settings: %{
        "display_name" => "GPT-4o",
        "system_prompt" => "You are a helpful assistant.",
        "temperature" => 0.7
      }
    },
    %{
      name: "gpt-4o-mini",
      provider: %{
        "name" => "OpenAI",
        "base_url" => "https://api.openai.com/v1"
      },
      model: "gpt-4o-mini",
      settings: %{
        "display_name" => "GPT-4o mini",
        "system_prompt" => "You are a friendly AI assistant.",
        "temperature" => 0.9
      }
    }
  ]

  def list do
    @presets
  end

  def get(name) do
    Enum.find(@presets, fn preset -> preset.name == name end)
  end

  def default() do
    get("gpt-4o-mini")
  end

  def with_preset(chat) do
    case chat do
      nil -> nil
      chat -> chat |> Map.put(:preset, get(chat.preset_name))
    end
  end

  def update_preset!(chat_id, preset_name) do
    Chat
    |> get!(chat_id)
    |> Chat.changeset(%{preset_name: preset_name})
    |> update!()
    |> with_preset()
  end
end
