defmodule AccumulatorWeb.UserJoinChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.ViewCount
  alias Phoenix.PubSub

  # Total website views are stored in "main" key
  @total_view_slug "main"

  @impl true
  def join(_room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  @spec handle_info(:after_join, Phoenix.Socket.t()) :: {:noreply, Phoenix.Socket.t()}
  def handle_info(:after_join, socket) do
    Presence.track(self(), "spotify-join", socket.id, %{})
    PubSub.subscribe(Accumulator.PubSub, "spotify:now_playing_update")

    {:ok, _} = Presence.track(socket, "user-join", %{})
    push(socket, "presence_state", Presence.list(socket))

    view_count = ViewCount.increment_count(@total_view_slug)
    broadcast!(socket, "view-count", %{count: view_count})

    PubSub.broadcast_from(Accumulator.PubSub, self(), "update:count", %{
      event: :main_page_view_count
    })

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{event: :spotify_now_playing, data: data} = _event_data, socket) do
    data =
      case data do
        {:ok, now_playing_data} -> %{type: "playing", item: now_playing_data}
        {:not_playing, message} -> %{type: "not-playing", message: message}
        {:error, _error} -> %{type: "error"}
      end

    push(socket, "spotify:now_playing_update", data)
    {:noreply, socket}
  end
end
