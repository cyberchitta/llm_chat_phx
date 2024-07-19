defmodule LlmChat.Schemas.Message do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "messages" do
    field(:content, :string)
    field(:role, :string)
    field(:turn_number, :integer)
    field(:attachments, {:array, :map}, default: [])

    belongs_to(:chat, LlmChat.Schemas.Chat, foreign_key: :chat_id, type: Ecto.UUID)

    belongs_to(:original_message, LlmChat.Schemas.Message,
      foreign_key: :original_message_id,
      type: Ecto.UUID
    )

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :role, :chat_id, :turn_number, :original_message_id, :attachments])
    |> validate_required([:role, :chat_id, :turn_number])
    |> validate_inclusion(:role, ["assistant", "user"])
    |> validate_attachments()
    |> assoc_constraint(:chat)
    |> assoc_constraint(:original_message)
  end

  defp validate_attachments(changeset) do
    validate_change(changeset, :attachments, fn _, attachments ->
      if Enum.all?(attachments, &valid_attachment?/1) do
        []
      else
        [attachments: "invalid attachment format"]
      end
    end)
  end

  defp valid_attachment?(%{url: url, content_type: content_type, filename: filename})
       when is_binary(url) and is_binary(content_type) and is_binary(filename),
       do: true

  defp valid_attachment?(_), do: false
end
