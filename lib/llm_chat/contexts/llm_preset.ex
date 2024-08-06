defmodule LlmChat.Contexts.LlmPreset do
  @presets [
    %{
      name: "gpt4_default",
      provider: %{
        "name" => "OpenAI",
        "base_url" => "https://api.openai.com/v1"
      },
      model: "gpt-4",
      settings: %{
        "display_name" => "GPT-4 Default",
        "system_prompt" => "You are a helpful assistant.",
        "max_tokens" => 2000,
        "temperature" => 0.7
      }
    },
    %{
      name: "gpt35_turbo",
      provider: %{
        "name" => "OpenAI",
        "base_url" => "https://api.openai.com/v1"
      },
      model: "gpt-3.5-turbo",
      settings: %{
        "display_name" => "GPT-3.5 Turbo",
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
end
