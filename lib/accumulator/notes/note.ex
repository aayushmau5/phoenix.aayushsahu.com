defmodule Accumulator.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:text, :string)
    timestamps()
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:text])
  end
end
