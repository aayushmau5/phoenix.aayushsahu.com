defmodule Accumulator.Repo.Migrations.StatsTable do
  use Ecto.Migration

  def change do
    create table(:stats) do
      add(:slug, :string, null: false)
      add(:views, :integer, null: false)
      add(:likes, :integer, null: false)
      timestamps(created_at: false)
    end
  end
end
