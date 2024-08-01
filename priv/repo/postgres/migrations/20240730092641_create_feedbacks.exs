defmodule LlmChat.RepoPostgres.Migrations.CreateFeedbacks do
  use Ecto.Migration

  def change do
    create table(:feedbacks, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: Ecto.UUID.generate())
      add(:message_id, references(:messages, type: :uuid, on_delete: :delete_all), null: false)
      add(:type, :string, null: false)

      timestamps()
    end

    create(unique_index(:feedbacks, [:message_id]))
  end
end
