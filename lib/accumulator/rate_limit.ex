defmodule Accumulator.RateLimit do
  @moduledoc """
  Rate limit module using Hammer.

  Uses ETS as backend.
  """
  use Hammer, backend: :ets
end
