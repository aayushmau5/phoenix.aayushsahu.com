defmodule AccumulatorWeb.UserJoinChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.ViewCount
  # alias Accumulator.PubSub
  alias Phoenix.PubSub

  # Total website views are stored in "main" key
  @total_view_slug "main"

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

    {:noreply, socket}
  end
end
