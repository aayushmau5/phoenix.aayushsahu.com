defmodule Accumulator.Notes.Workspace do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workspaces" do
    field(:title, :string)
    field(:is_public, :boolean)
    has_many(:notes, Accumulator.Notes.Note)
    timestamps(type: :utc_datetime)
  end

  def changeset(workspace, params \\ %{}) do
    workspace
    |> cast(params, [:title, :is_public])
    |> validate_length(:title, min: 2)
  end
end
