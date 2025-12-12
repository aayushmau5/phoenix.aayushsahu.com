defmodule AccumulatorWeb.BlogChannel do
  use Phoenix.Channel

  alias AccumulatorWeb.Presence
  alias Accumulator.{Stats, RateLimit}
  alias Phoenix.PubSub

  @pubsub Accumulator.PubSub

  def join(room_id, _params, socket) do
    send(self(), {:after_join, room_id})
    {:ok, socket}
  end

  def handle_info({:after_join, room_id}, socket) do
    {:ok, _} = Presence.track(socket, room_id, %{})
    push(socket, "presence_state", Presence.list(socket))

    # Rate limit: 10 view increments per minute per IP per blog
    ip = socket.assigns[:client_ip] || "unknown"

    blog_stats =
      case RateLimit.hit("blog_view:#{ip}:#{room_id}", 60_000, 10) do
        {:allow, _} ->
          stats = Stats.increment_blog_view_count(room_id)
          broadcast!(socket, "blog-view-count", %{count: stats.views})

          PubSub.broadcast_from(@pubsub, self(), "update:count", %{
            event: :blog_page_view_count,
            key: room_id
          })

          stats

        {:deny, _} ->
          Stats.get_blog_data(room_id)
      end

    push(socket, "blog-view-count", %{count: blog_stats.views})
    push(socket, "likes-count", %{count: blog_stats.likes})

    {:noreply, socket}
  end

  def handle_in("like", %{"topic" => topic}, socket) do
    # Rate limit: 10 likes per minute per IP per blog
    ip = socket.assigns[:client_ip] || "unknown"

    case RateLimit.hit("blog_like:#{ip}:#{topic}", 60_000, 10) do
      {:allow, _} ->
        blog_stats = Stats.increment_blog_like_count(topic)
        broadcast!(socket, "likes-count", %{count: blog_stats.likes})

        PubSub.broadcast_from(@pubsub, self(), "update:count", %{
          event: :blog_like_count,
          key: topic
        })

        {:reply, {:ok, %{liked: true}}, socket}

      {:deny, _} ->
        {:reply, {:error, %{reason: "rate_limited"}}, socket}
    end
  end
end
