defmodule Accumulator.Helpers do
  @timezone "Asia/Kolkata"

  def date_passed?(date) do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)
    if DateTime.compare(current_date_time, date) == :lt, do: false, else: true
  end

  def get_future_time(seconds \\ 0) do
    DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.add(seconds)
  end

  def days_ago(date_string) do
    date = Date.from_iso8601!(date_string)
    today = DateTime.now!(@timezone) |> DateTime.to_date()

    case Date.diff(today, date) do
      0 -> "today"
      1 -> "yesterday"
      x -> "#{x} days ago"
    end
  end

  def convert_timestamps_tz(map) do
    map
    |> Map.update!(:inserted_at, fn utc_timestamp ->
      DateTime.shift_zone!(utc_timestamp, @timezone)
    end)
    |> Map.update!(:updated_at, fn utc_timestamp ->
      DateTime.shift_zone!(utc_timestamp, @timezone)
    end)
  end

  def get_utc_datetime_from_date(date \\ Date.utc_today()) do
    date_tuple = date |> Date.to_erl()

    NaiveDateTime.from_erl!({date_tuple, {0, 0, 0}})
    |> NaiveDateTime.add(1, :day)
    |> DateTime.from_naive!("Etc/UTC")
  end
end
