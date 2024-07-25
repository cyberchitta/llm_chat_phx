defmodule LlmChat.Schemas.Message do
  @moduledoc false
  use Ecto.Schema
  @timestamps_opts [type: :utc_datetime]
  import Ecto.Changeset

  @primary_key {:id, Ecto.UUID, autogenerate: true}
  schema "messages" do
    field(:turn_number, :integer)
    field(:path, :string)
    field(:role, :string)
    field(:content, :string)
    field(:attachments, {:array, :map}, default: [])

    belongs_to(:chat, LlmChat.Schemas.Chat, foreign_key: :chat_id, type: Ecto.UUID)
    belongs_to(:parent, LlmChat.Schemas.Message, foreign_key: :parent_id, type: Ecto.UUID)

    timestamps()
  end

  def changeset(message, attrs) do
    message
    |> cast(attrs, [:chat_id, :parent_id, :turn_number, :path, :role, :content, :attachments])
    |> validate_required([:role, :chat_id, :turn_number, :path])
    |> validate_content_or_attachments()
    |> validate_inclusion(:role, ["assistant", "user"])
    |> validate_attachments()
    |> assoc_constraint(:chat)
    |> assoc_constraint(:parent)
    |> unique_constraint([:chat_id, :turn_number])
  end

  defp validate_content_or_attachments(changeset) do
    content = get_field(changeset, :content)
    attachments = get_field(changeset, :attachments)

    if is_nil(content) and Enum.empty?(attachments) do
      add_error(changeset, :content, "can't be blank when there are no attachments")
    else
      changeset
    end
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
