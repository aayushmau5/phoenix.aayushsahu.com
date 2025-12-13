defmodule Accumulator.Stats.DailyStat do
  use Ecto.Schema

  schema "daily_stats" do
    field(:slug, :string)
    field(:date, :date)
    field(:views, :integer, default: 0)
    field(:likes, :integer, default: 0)

    timestamps()
  end
end
