defmodule LlmChat.Repo.Postgres.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add(:id, :uuid, primary_key: true, default:  Ecto.UUID.generate())
      add(:role, :string, null: false)
      add(:content, :text, null: true)
      add(:turn_number, :integer, null: false)
      add(:attachments, {:array, :string}, default: [])

      add(:chat_id, references(:chats, type: :uuid, on_delete: :delete_all), null: false)
      add(:original_message_id, references(:messages, type: :uuid, on_delete: :nilify_all))

      timestamps()
    end

    create(index(:messages, [:chat_id]))
    create(index(:messages, [:original_message_id]))
  end
end
