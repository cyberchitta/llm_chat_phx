defmodule LlmChat.Repo.Migrations.CreateLlmPresets do
  use Ecto.Migration

  def change do
    create table(:llm_presets, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:provider, :map, null: false)
      add(:model, :string, null: false)
      add(:settings, :map, null: false)

      timestamps()
    end

    create(unique_index(:llm_presets, [:name]))
  end
end
