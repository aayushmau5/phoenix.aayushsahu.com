defmodule Accumulator.Repo.Migrations.RemoveFiles do
  use Ecto.Migration

  def change do
    alter table(:notes) do
      remove(:files)
    end
  end
end
