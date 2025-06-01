defmodule Accumulator.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset
  alias Accumulator.ProfanityFilter

  schema "comments" do
    field(:content, :string)
    field(:author, :string)
    field(:blog_slug, :string)
    belongs_to(:parent, __MODULE__)
    has_many(:replies, __MODULE__, foreign_key: :parent_id)

    timestamps()
  end

  @doc false
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :author, :blog_slug, :parent_id])
    |> validate_required([:content, :blog_slug])
    |> validate_content_profanity()
  end

  defp validate_content_profanity(changeset) do
    case get_field(changeset, :content) do
      nil -> changeset
      content ->
        case ProfanityFilter.check_profanity(content) do
          {:ok, _} -> changeset
          {:error, :contains_profanity} ->
            add_error(changeset, :content, "contains inappropriate language")
          {:error, :invalid_input} ->
            add_error(changeset, :content, "is invalid")
          {:error, _} ->
            # For API errors, we'll allow the comment but log the issue
            changeset
        end
    end
  end
end
