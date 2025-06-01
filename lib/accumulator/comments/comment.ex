defmodule Accumulator.Comments.Comment do
  use Ecto.Schema
  import Ecto.Changeset

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
  end
end
