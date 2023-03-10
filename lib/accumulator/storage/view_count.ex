defmodule Accumulator.Storage.ViewCount do
  @spec get_count(slug :: binary()) :: integer()
  def get_count(slug) do
    {:ok, count_string} = Redix.command(:redix, ["GET", slug])
    String.to_integer(count_string)
  end

  @spec increment_count(slug :: binary()) :: integer()
  def increment_count(slug) do
    {:ok, count} = Redix.command(:redix, ["INCR", slug])
    count
  end
end
