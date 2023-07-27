defmodule Accumulator.Spotify.Schema do
  use Ecto.Schema

  schema "spotify" do
    field(:type, :string)
    field(:data, :string)
    field(:expire_at, :utc_datetime)

    timestamps(created_at: false)
  end
end
