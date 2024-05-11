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
  end
end
