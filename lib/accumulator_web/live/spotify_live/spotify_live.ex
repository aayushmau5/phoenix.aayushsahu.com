defmodule AccumulatorWeb.SpotifyLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Spotify
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        {:ok, _} = Presence.track(self(), "spotify-join", socket.id, %{})
        PubSub.subscribe(Accumulator.PubSub, "spotify:now_playing_update")

        now_playing = Spotify.get_cached_now_playing()

        PubSub.broadcast_from(Accumulator.PubSub, self(), "spotify:now_playing_update", %{
          event: :spotify_now_playing,
          data: now_playing
        })

        assign(socket,
          now_playing: now_playing,
          top_tracks: Spotify.get_top_tracks(),
          top_artists: Spotify.get_top_artists()
        )
      else
        assign(socket,
          now_playing: nil,
          top_tracks: nil,
          top_artists: nil
        )
      end

    {:ok, assign(socket, page_title: "Spotify")}
  end

  @impl true
  def handle_info(%{event: :spotify_now_playing, data: data} = _event_data, socket) do
    {:noreply, assign(socket, now_playing: data)}
  end
end
