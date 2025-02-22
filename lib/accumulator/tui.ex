defmodule Accumulator.TUI do
  @moduledoc """
  Event for TUI
  """

  defmodule Payload do
    @moduledoc """
    Event Payload
    """

    @derive {Jason.Encoder, only: [:action, :data]}
    @type t :: %__MODULE__{
            action: String.t(),
            data: any()
          }

    defstruct [:action, :data]
  end

  @derive {Jason.Encoder, only: [:name, :payload]}
  @type t :: %__MODULE__{
          name: String.t(),
          payload: Payload.t()
        }

  @enforce_keys [:name, :payload]
  defstruct [:name, :payload]
end
