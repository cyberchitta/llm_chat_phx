defmodule LlmChat.Repo.Migrations.CreateChatApiCalls do
  use Ecto.Migration

  def change do
    create table(:chat_api_calls, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:preset_name, :string, null: false)
      add(:contents, :map, null: false)
      add(:input_tokens, :integer, null: false)
      add(:output_tokens, :integer, null: false)
      add(:total_tokens, :integer, null: false)
      add(:duration_ms, :integer, null: false)

      add(:output_id, references(:messages, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      timestamps()
    end

    create(index(:chat_api_calls, [:output_id]))
  end
end
