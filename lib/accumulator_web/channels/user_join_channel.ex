defmodule AccumulatorWeb.UserJoinChannel do
  use Phoenix.Channel

  alias Accumulator.{Stats, Spotify}
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  @pubsub Accumulator.PubSub
  @spotify_update_event "spotify:now_playing_update"

  @impl true
  def join(_room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @spec handle_info(:after_join, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, "user-join", %{})
    push(socket, "presence_state", Presence.list(socket))

    main_stats = Stats.increment_main_view_count()
    broadcast!(socket, "view-count", %{count: main_stats.views})

    PubSub.broadcast_from(@pubsub, self(), "update:count", %{
      event: :main_page_view_count
    })

    # Spotify now playing
    Presence.track(self(), "spotify-join", socket.id, %{})
    PubSub.subscribe(@pubsub, @spotify_update_event)
    now_playing = Spotify.get_cached_now_playing()
    data = process_spotify_now_playing(now_playing)
    push(socket, @spotify_update_event, data)

    PubSub.broadcast_from(@pubsub, self(), "spotify:now_playing_update", %{
      event: :spotify_now_playing,
      data: now_playing
    })

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: :spotify_now_playing, data: data} = _event_data, socket) do
    data = process_spotify_now_playing(data)
    push(socket, @spotify_update_event, data)
    {:noreply, socket}
  end

  defp process_spotify_now_playing(data) do
    case data do
      {:ok, now_playing_data} -> %{state: "playing", item: now_playing_data}
      {:not_playing, message} -> %{state: "not-playing", message: message}
      {:error, _error} -> %{state: "error"}
    end
  end
end
