defmodule Accumulator.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:text, :string)
    timestamps()

    embeds_many(:files, Accumulator.Notes.File, on_replace: :delete)
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:text])
    |> cast_embed(:files)
  end
end
