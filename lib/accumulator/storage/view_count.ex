defmodule Accumulator.Storage.ViewCount do
  def increment_count(slug) do
    {:ok, count} = Redix.command(:redix, ["INCR", slug])
    count
  end
end
