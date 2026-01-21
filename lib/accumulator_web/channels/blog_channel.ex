defmodule AccumulatorWeb.BlogChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.Stats
  alias PubSubContract.Bus
  alias Accumulator.PubSub.Messages.Local.CountUpdate

  @pubsub Accumulator.PubSub

  def join(room_id, _params, socket) do
    send(self(), {:after_join, room_id})
    {:ok, socket}
  end

  def handle_info({:after_join, room_id}, socket) do
    {:ok, _} = Presence.track(socket, room_id, %{})
    push(socket, "presence_state", Presence.list(socket))

    blog_stats = Stats.increment_blog_view_count(room_id)
    broadcast!(socket, "blog-view-count", %{count: blog_stats.views})
    push(socket, "likes-count", %{count: blog_stats.likes})

    Bus.publish_from(@pubsub, self(), CountUpdate.new!(event: :blog_page_view_count, key: room_id))

    {:noreply, socket}
  end

  def handle_in("like", %{"topic" => topic} = params, socket) do
    blog_stats = Stats.increment_blog_like_count(topic)
    broadcast!(socket, "likes-count", %{count: blog_stats.likes})

    Bus.publish_from(@pubsub, self(), CountUpdate.new!(event: :blog_like_count, key: topic))

    {:reply, {:ok, params}, socket}
  end
end
