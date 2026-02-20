defmodule Accumulator.Stats.DailyUserAgentStat do
  use Ecto.Schema

  schema "daily_user_agent_stats" do
    field(:date, :date)
    field(:browser, :string)
    field(:os, :string)
    field(:device, :string)
    field(:count, :integer, default: 0)

    timestamps()
  end
end
