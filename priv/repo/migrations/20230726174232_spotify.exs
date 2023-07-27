defmodule Accumulator.Repo.Migrations.Spotify do
  use Ecto.Migration

  def change do
    create table(:spotify) do
      add(:type, :string, null: false)
      add(:data, :text, null: false)
      add(:expire_at, :utc_datetime, null: false)
      timestamps(created_at: false)
    end
  end
end
