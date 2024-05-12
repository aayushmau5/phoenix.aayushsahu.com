defmodule Accumulator.Notes.Note do
  use Ecto.Schema
  import Ecto.Changeset

  schema "notes" do
    field(:text, :string)
    belongs_to(:workspace, Accumulator.Notes.Workspace)
    timestamps()
  end

  def changeset(note, params \\ %{}) do
    note
    |> cast(params, [:text, :workspace_id])
    |> validate_required([:workspace_id])
    |> foreign_key_constraint(:workspace_id)
  end
end
