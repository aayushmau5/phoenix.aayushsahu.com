defmodule Accumulator.Repo.Migrations.CreateDailyUserAgentStats do
  use Ecto.Migration

  def change do
    create table(:daily_user_agent_stats) do
      add(:date, :date, null: false)
      add(:browser, :string, null: false)
      add(:os, :string, null: false)
      add(:device, :string, null: false)
      add(:count, :integer, null: false, default: 0)

      timestamps()
    end

    create(unique_index(:daily_user_agent_stats, [:date, :browser, :os, :device]))
    create(index(:daily_user_agent_stats, [:date]))
  end
end
