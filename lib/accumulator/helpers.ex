defmodule Accumulator.Helpers do
  def date_passed?(date) do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)
    if DateTime.compare(current_date_time, date) == :lt, do: false, else: true
  end

  def get_future_time(seconds \\ 0) do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(seconds)
  end
end
