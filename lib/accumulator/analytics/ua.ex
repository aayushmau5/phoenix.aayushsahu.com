defmodule Accumulator.Analytics.UA do
  @moduledoc """
  Parses user agent strings into coarse browser/OS/device dimensions
  for aggregated analytics storage.
  """

  @type dimensions :: %{browser: String.t(), os: String.t(), device: String.t()}

  @spec parse(String.t() | nil) :: dimensions()
  def parse(nil), do: unknown()
  def parse(""), do: unknown()

  def parse(ua_string) do
    ua = UAParser.parse(ua_string)

    browser = ua.family || "Unknown"
    os = (ua.os && ua.os.family) || "Unknown"
    device = sanitize_device(ua.device)

    if browser == "Unknown" and os == "Unknown" and device == "Unknown" do
      unknown()
    else
      %{browser: browser, os: os, device: device}
    end
  end

  @max_device_length 30

  defp sanitize_device(nil), do: "Unknown"

  defp sanitize_device(%{family: family, brand: brand}) do
    cond do
      is_binary(family) and String.length(family) <= @max_device_length -> family
      is_binary(brand) -> brand
      true -> "Unknown"
    end
  end

  defp sanitize_device(_), do: "Unknown"

  defp unknown, do: %{browser: "Unknown", os: "Unknown", device: "Unknown"}
end
