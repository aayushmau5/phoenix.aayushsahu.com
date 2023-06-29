defmodule AccumulatorWeb.UserJoinChannel do
  use Phoenix.Channel

  alias Accumulator.Storage.ViewCount
  alias Accumulator.Spotify
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  # Total website views are stored in "main" key
  @total_view_slug "main"
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

    view_count = ViewCount.increment_count(@total_view_slug)
    broadcast!(socket, "view-count", %{count: view_count})

    PubSub.broadcast_from(Accumulator.PubSub, self(), "update:count", %{
      event: :main_page_view_count
    })

    # Spotify now playing
    Presence.track(self(), "spotify-join", socket.id, %{})
    PubSub.subscribe(Accumulator.PubSub, @spotify_update_event)
    data = Spotify.get_cached_now_playing() |> process_spotify_now_playing()
    push(socket, @spotify_update_event, data)

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
