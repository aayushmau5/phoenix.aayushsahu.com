defmodule :"Elixir.Accumulator.Repo.Migrations.Pastes-files" do
  use Ecto.Migration

  def change do
    alter table(:pastes) do
      add(:files, :map)
      add(:storage_directory, :string)
    end
  end
end
