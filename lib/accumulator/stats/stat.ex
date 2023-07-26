defmodule Accumulator.Stats.Stat do
  use Ecto.Schema

  schema "stats" do
    field(:slug, :string)
    field(:views, :integer, default: 1)
    field(:likes, :integer, default: 0)
    timestamps(created_at: false)
  end
end
