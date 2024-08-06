defmodule LlmChat.Schemas.LlmPreset do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "llm_presets" do
    field(:name, :string)
    field(:provider, :map)
    field(:model, :string)
    field(:settings, :map)

    timestamps()
  end

  def changeset(llm_preset, attrs) do
    llm_preset
    |> cast(attrs, [:name, :provider, :model, :settings])
    |> validate_required([:name, :provider, :model, :settings])
    |> unique_constraint(:name)
  end
end
