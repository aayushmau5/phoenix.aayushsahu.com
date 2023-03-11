defmodule AccumulatorWeb.BlogChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.{LikesCount, ViewCount}
  alias Phoenix.PubSub

  def join(room_id, _params, socket) do
    send(self(), {:after_join, room_id})
    {:ok, socket}
  end

  def handle_info({:after_join, room_id}, socket) do
    {:ok, _} = Presence.track(socket, room_id, %{})
    push(socket, "presence_state", Presence.list(socket))

    view_count = ViewCount.increment_count(room_id)
    broadcast!(socket, "blog-view-count", %{count: view_count})

    PubSub.broadcast_from(Accumulator.PubSub, self(), "update:count", %{
      event: :blog_page_view_count,
      key: room_id
    })

    likes_count = LikesCount.get_count("like-#{room_id}")
    push(socket, "likes-count", %{count: likes_count})

    {:noreply, socket}
  end

  def handle_in("like", %{"topic" => topic} = params, socket) do
    likes_count = LikesCount.increment_count("like-#{topic}")
    broadcast!(socket, "likes-count", %{count: likes_count})

    PubSub.broadcast_from(Accumulator.PubSub, self(), "update:count", %{
      event: :blog_like_count,
      key: topic
    })

    {:reply, {:ok, params}, socket}
  end
end
