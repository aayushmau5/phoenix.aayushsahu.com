defmodule Accumulator.Repo.Migrations.CreatePhotos do
  use Ecto.Migration

  def change do
    create table(:photos) do
      add :caption, :text
      add :place, :text
      add :taken_at, :utc_datetime, null: false
      add :width, :integer, null: false
      add :height, :integer, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:photos, [:taken_at])
  end
end
