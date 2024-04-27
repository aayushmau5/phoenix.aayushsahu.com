defmodule Accumulator.Repo.Migrations.CreateNotes do
  use Ecto.Migration

  # https://stackoverflow.com/questions/60623138/ecto-creating-a-constraint-where-only-one-column-is-not-null

  def change do
    create table(:notes) do
      add(:text, :text)
      add(:files, :map)
      timestamps()
    end
  end
end
