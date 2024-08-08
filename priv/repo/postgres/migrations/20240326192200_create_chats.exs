defmodule LlmChat.Repo.Postgres.Migrations.CreateChats do
  use Ecto.Migration

  def change do
    create table(:chats, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:name, :string, null: false)
      add(:ui_path, :text)
      add(:preset_name, :string, null: false)
      add(:max_turn_number, :integer, default: 0, null: false)

      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(index(:chats, [:user_id]))
  end
end
