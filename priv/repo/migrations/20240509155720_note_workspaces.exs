defmodule Accumulator.Repo.Migrations.NoteWorkspaces do
  use Ecto.Migration

  def change do
    create table(:workspaces) do
      add(:title, :string)
      timestamps()
    end

    alter table(:notes) do
      add(:workspace_id, references(:workspaces, on_delete: :delete_all))
    end

    flush()

    # create a "default" workspace and update existing records to have this default workspace
    {:ok, default_workspace} =
      Accumulator.Repo.insert(%Accumulator.Notes.Workspace{title: "default"})

    Accumulator.Repo.update_all("notes", set: [workspace_id: default_workspace.id])
  end

  def down() do
    alter table(:notes) do
      remove(:workspace_id)
    end

    drop(table("workspaces"))
  end
end
