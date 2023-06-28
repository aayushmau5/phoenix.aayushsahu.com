defmodule AccumulatorWeb.SpotifyLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Spotify

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        # TODO: think about spawning a task to get now playing and top tracks data so that they don't block each other
        # Task.async(fn -> Spotify.get_now_playing() end)
        # Task.async(fn -> Spotify.get_top_tracks() end)
        assign(socket,
          now_playing: Spotify.get_now_playing(),
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
  def handle_event("refresh-now-playing", _params, socket) do
    now_playing = Spotify.get_now_playing()
    {:noreply, assign(socket, now_playing: now_playing)}
  end
end
