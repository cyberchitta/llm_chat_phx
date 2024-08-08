defmodule LlmChat.Contexts.LlmPreset do
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
        "max_tokens" => 2000,
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
        "max_tokens" => 1000,
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
end
