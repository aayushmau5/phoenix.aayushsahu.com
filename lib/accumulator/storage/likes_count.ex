defmodule Accumulator.Storage.LikesCount do
  def get_count(slug) do
    case Redix.command(:redix, ["GET", slug]) do
      {:ok, nil} ->
        {:ok, _} = Redix.command(:redix, ["SET", slug, 0])
        0

      {:ok, count} ->
        String.to_integer(count)
    end
  end

  def increment_count(slug) do
    {:ok, count} = Redix.command(:redix, ["INCR", slug])
    count
  end
end
