defmodule Accumulator.Extension.Bookmarks do
  use Ecto.Schema
  import Ecto.Changeset

  schema "extension_bookmarks" do
    field(:url, :string)
    field(:title, :string)
    field(:browser_id, :string)
    timestamps(updated_at: false)
  end

  def changeset(bookmark, params \\ %{}) do
    fields = [:url, :title, :browser_id]

    bookmark
    |> cast(params, fields)
    |> validate_required(fields)
  end
end
