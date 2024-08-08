defmodule LlmChat.RepoPostgres.Migrations.CreateFeedbacks do
  use Ecto.Migration

  def change do
    create table(:feedbacks, primary_key: false) do
      add(:id, :binary_id, primary_key: true)

      add(:message_id, references(:messages, type: :binary_id, on_delete: :delete_all),
        null: false
      )

      add(:type, :string, null: false)

      timestamps()
    end

    create(unique_index(:feedbacks, [:message_id]))
  end
end
