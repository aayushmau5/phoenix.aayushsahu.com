defmodule Accumulator.PubSub.Messages.Spotify.NowPlaying do
  @moduledoc """
  Broadcast when Spotify now-playing status changes. Local only.
  """
  use PubSubContract.Message

  message do
    field(:data, :any, required: true)
  end

  @impl true
  def topic, do: "spotify:now_playing_update"

  @impl true
  def validate(%__MODULE__{data: data}) when not is_nil(data), do: :ok
  def validate(_), do: {:error, :invalid_data}
end
