defmodule LlmChat.Repo.Postgres.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats, primary_key: false) do
      add(:id, :uuid, primary_key: true, default:  Ecto.UUID.generate())
      add(:name, :string, null: false)

      add(:user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:chats, [:user_id]))
  end
end
