defmodule Accumulator.Notes.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspaces" do
    field(:title, :string)
    has_many(:notes, Accumulator.Notes.Note)
    timestamps()
  end

  def changeset(workspace, params \\ %{}) do
    workspace
    |> cast(params, [:title])
    |> validate_length(:title, min: 2)
  end
end
