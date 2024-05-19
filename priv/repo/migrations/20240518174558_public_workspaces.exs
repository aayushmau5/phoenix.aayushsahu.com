defmodule Accumulator.Repo.Migrations.PublicWorkspaces do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      add(:is_public, :boolean, default: false)
    end
  end
end
