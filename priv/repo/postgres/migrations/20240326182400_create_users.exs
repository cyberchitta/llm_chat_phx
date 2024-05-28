defmodule LlmChat.Repo.Postgres.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :uuid, primary_key: true, default: Ecto.UUID.generate())
      add(:google_id, :string, null: false)
      add(:email, :string, null: false)
      add(:name, :string, null: false)
      add(:avatar_url, :string)

      timestamps()
    end

    create(unique_index(:users, [:google_id]))
    create(unique_index(:users, [:email]))
  end
end
