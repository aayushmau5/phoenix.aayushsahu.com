defmodule AccumulatorWeb.SpotifyLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Spotify
  alias AccumulatorWeb.Presence
  alias PubSubContract.Bus
  alias Accumulator.PubSub.Messages.Spotify.NowPlaying

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        {:ok, _} = Presence.track(self(), "spotify-join", socket.id, %{})
        Bus.subscribe(Accumulator.PubSub, NowPlaying)

        now_playing = Spotify.get_cached_now_playing()

        Bus.publish_from(Accumulator.PubSub, self(), NowPlaying.new!(data: now_playing))

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
  def handle_info(%NowPlaying{data: data}, socket) do
    {:noreply, assign(socket, now_playing: data)}
  end
end
