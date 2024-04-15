defmodule Accumulator.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:heading, :string)
    field(:text, :string)
    field(:files, {:array, :string}, default: [])
    timestamps()
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:heading, :text, :files])
    |> validate_length(:heading, max: 200)
  end
end
