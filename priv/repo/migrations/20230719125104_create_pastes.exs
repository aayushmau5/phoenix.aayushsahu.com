defmodule Accumulator.Repo.Migrations.CreatePastes do
  use Ecto.Migration

  def change do
    create table(:pastes) do
      add(:title, :string, null: false)
      add(:content, :text, null: false)
      add(:expire_at, :utc_datetime, null: false)
      timestamps(updated_at: false)
    end
  end
end
