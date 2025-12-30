defmodule Accumulator.Repo.Migrations.YearLog do
  use Ecto.Migration

  def change do
    create table(:year_logs) do
      add :text, :text
      add :logged_on, :date, null: false

      timestamps(updated_at: false)
    end

    create unique_index(:year_logs, [:logged_on])
  end
end
