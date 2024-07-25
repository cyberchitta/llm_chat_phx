defmodule LlmChat.Repo.Postgres.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add(:id, :uuid, primary_key: true, default:  Ecto.UUID.generate())
      add(:turn_number, :integer, null: false)
      add(:path, :text, null: false, default: "")
      add(:role, :string, null: false)
      add(:content, :text, null: true)
      add(:attachments, {:array, :map}, default: [])

      add(:chat_id, references(:chats, type: :uuid, on_delete: :delete_all), null: false)
      add(:parent_id, references(:messages, type: :uuid, on_delete: :nilify_all), null: true)

      timestamps()
    end

    create(index(:messages, [:chat_id]))
    create(index(:messages, [:path]))
    create(index(:messages, [:parent_id]))
    create(index(:messages, [:chat_id, :path]))
  end
end
