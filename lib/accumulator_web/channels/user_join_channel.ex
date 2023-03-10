defmodule AccumulatorWeb.UserJoinChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.ViewCount

  def join(_room_id, _params, socket) do
    send(self(), :after_join)
    {:ok, socket}
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.id, %{})
    push(socket, "presence_state", Presence.list(socket))

    view_count = ViewCount.increment_count("main")
    broadcast!(socket, "view-count", %{count: view_count})

    {:noreply, socket}
  end
end
