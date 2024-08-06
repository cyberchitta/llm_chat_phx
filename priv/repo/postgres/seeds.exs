alias LlmChat.RepoPostgres
alias LlmChat.Schemas.LlmPreset
alias LlmChat.Contexts.LlmPreset, as: PresetContext

Enum.each(PresetContext.list(), fn preset ->
  %LlmPreset{}
  |> LlmPreset.changeset(preset)
  |> RepoPostgres.insert!(on_conflict: :replace_all, conflict_target: [:name])
end)
