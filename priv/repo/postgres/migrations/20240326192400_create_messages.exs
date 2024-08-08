defmodule LlmChat.Repo.Postgres.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:turn_number, :integer, null: false)
      add(:path, :text, null: false, default: "")
      add(:role, :string, null: false)
      add(:content, :text, null: false)
      add(:attachments, {:array, :map}, default: [])

      add(:chat_id, references(:chats, type: :binary_id, on_delete: :delete_all), null: false)
      add(:parent_id, references(:messages, type: :binary_id, on_delete: :nilify_all), null: true)

      timestamps()
    end

    create(index(:messages, [:chat_id]))
    create(index(:messages, [:path]))
    create(index(:messages, [:parent_id]))
    create(index(:messages, [:chat_id, :path]))
  end
end
