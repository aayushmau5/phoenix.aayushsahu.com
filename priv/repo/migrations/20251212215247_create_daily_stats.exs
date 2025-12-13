defmodule Accumulator.Repo.Migrations.CreateDailyStats do
  use Ecto.Migration

  def change do
    create table(:daily_stats) do
      add(:slug, :string, null: false)
      add(:date, :date, null: false)
      add(:views, :integer, null: false, default: 0)
      add(:likes, :integer, null: false, default: 0)

      timestamps()
    end

    create(unique_index(:daily_stats, [:slug, :date]))
    create(index(:daily_stats, [:slug]))
    create(index(:daily_stats, [:date]))
  end
end
