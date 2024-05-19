defmodule Accumulator.Helpers do
  def date_passed?(date) do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)
    if DateTime.compare(current_date_time, date) == :lt, do: false, else: true
  end

  def get_future_time(seconds \\ 0) do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(seconds)
  end

  def days_ago(date_string) do
    date = Date.from_iso8601!(date_string)
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 -> "today"
      1 -> "yesterday"
      x -> "#{x} days ago"
    end
  end
end
