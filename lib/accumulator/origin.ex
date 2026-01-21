defmodule Accumulator.Origin do
  @allowed_hosts ["aayushsahu.com", "phoenix.aayushsahu.com"]

  def my_check_origin?(%URI{scheme: scheme, host: host} = _uri) do
    case scheme do
      # "moz-extension" -> true
      # "chrome-extension" -> true
      "https" -> if host in @allowed_hosts, do: true, else: false
      _ -> true
    end
  end
end
