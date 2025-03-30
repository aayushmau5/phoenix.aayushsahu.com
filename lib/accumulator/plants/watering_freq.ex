defmodule Accumulator.Plants.WateringFreq do
  @week_days %{
    "daily" => 1,
    "weekly" => 7,
    "biweekly" => 14
  }
  @valid_phrases ["biweekly", "weekly", "daily", "upper soil dry"]
  @regex ~r/^(\d+)\s+(weeks?|days?)$/

  def validate_watering_frequency(""), do: {:ok, ""}
  def validate_watering_frequency(value) when value in @valid_phrases, do: {:ok, value}

  def validate_watering_frequency(value) do
    case Regex.match?(@regex, value) do
      true ->
        {:ok, value}

      false ->
        {:error,
         "Invalid format. Accepts: '<x> weeks', '<x> days', biweekly, weekly, daily, 'upper soil dry'"}
    end
  end

  def convert_to_date(%Date{} = curr_date, frequency) do
    if frequency in Map.keys(@week_days) do
      days = Map.get(@week_days, frequency)
      Date.add(curr_date, days)
    else
      case Regex.run(@regex, frequency) do
        [_, num, "day" <> _] -> Date.add(curr_date, String.to_integer(num))
        [_, num, "week" <> _] -> Date.add(curr_date, String.to_integer(num) * 7)
        _ -> :error
      end
    end
  end
end
