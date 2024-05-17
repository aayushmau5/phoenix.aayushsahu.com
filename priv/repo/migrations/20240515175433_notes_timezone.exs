defmodule Accumulator.Repo.Migrations.NotesTimezone do
  use Ecto.Migration

  def change do
    alter table(:workspaces) do
      modify(:inserted_at, :utc_datetime)
      modify(:updated_at, :utc_datetime)
    end

    alter table(:notes) do
      modify(:inserted_at, :utc_datetime)
      modify(:updated_at, :utc_datetime)
    end
  end

  def down() do
    alter table(:workspaces) do
      modify(:inserted_at, :naive_datetime)
      modify(:updated_at, :naive_datetime)
    end

    alter table(:notes) do
      modify(:inserted_at, :naive_datetime)
      modify(:updated_at, :naive_datetime)
    end
  end
end
