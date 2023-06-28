defmodule Accumulator.Scheduler do
  use Quantum, otp_app: :accumulator

  alias Accumulator.Spotify
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  def spotify_now_playing_job do
    users_connected = Presence.list("spotify-join") |> map_size()

    if users_connected != 0 do
      now_playing = Spotify.get_now_playing()

      PubSub.broadcast_from(Accumulator.PubSub, self(), "spotify:now_playing_update", %{
        event: :spotify_now_playing,
        data: now_playing
      })
    end
  end
end
