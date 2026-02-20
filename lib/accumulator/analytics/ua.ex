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
    device = (ua.device && ua.device.family) || "Unknown"

    if browser == "Unknown" and os == "Unknown" and device == "Unknown" do
      unknown()
    else
      %{browser: browser, os: os, device: device}
    end
  end

  defp unknown, do: %{browser: "Unknown", os: "Unknown", device: "Unknown"}
end
