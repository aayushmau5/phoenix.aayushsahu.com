defmodule Accumulator.Repo.Migrations.Plants do
  use Ecto.Migration

  def change do
    create table(:plants) do
      add :name, :text
      add :image, :string
      add :info, :text
      add :care, :text
      add :watering_frequency, :text
      add :watered_on, :date
      add :next_water_on, :date
      add :potting_notes, :text
      timestamps()
    end
  end
end
