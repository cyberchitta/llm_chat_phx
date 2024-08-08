defmodule LlmChat.Schemas.ChatApiCall do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "chat_api_calls" do
    field(:preset_name, :string)
    field(:contents, :map)
    field(:input_tokens, :integer)
    field(:output_tokens, :integer)
    field(:total_tokens, :integer)
    field(:duration_ms, :integer)

    belongs_to(:output, LlmChat.Schemas.Message, foreign_key: :output_id)

    timestamps()
  end

  def changeset(chat_api_call, attrs) do
    chat_api_call
    |> cast(attrs, [
      :preset_name,
      :contents,
      :input_tokens,
      :output_tokens,
      :total_tokens,
      :duration_ms,
      :output_id
    ])
    |> validate_required([
      :preset_name,
      :contents,
      :input_tokens,
      :output_tokens,
      :total_tokens,
      :duration_ms,
      :output_id
    ])
    |> assoc_constraint(:output)
  end
end
