alias LlmChat.RepoPostgres
alias LlmChat.Schemas.LlmPreset

defp insert_preset(attrs) do
  %LlmPreset{}
  |> LlmPreset.changeset(attrs)
  |> RepoPostgres.insert!()
end

[
  %{
    name: "GPT-4 Default",
    provider: %{
      "name" => "OpenAI",
      "base_url" => "https://api.openai.com/v1"
    },
    model: "gpt-4",
    settings: %{
      "system_prompt" => "You are a helpful assistant.",
      "max_tokens" => 2000,
      "temperature" => 0.7
    }
  },
  %{
    name: "GPT-3.5 Turbo",
    provider: %{
      "name" => "OpenAI",
      "base_url" => "https://api.openai.com/v1"
    },
    model: "gpt-3.5-turbo",
    settings: %{
      "system_prompt" => "You are a friendly AI assistant.",
      "max_tokens" => 1000,
      "temperature" => 0.9
    }
  }
]
|> Enum.each(&insert_preset/1)
