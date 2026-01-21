defmodule Accumulator.Analytics.Subscriber do
  @moduledoc """
  Subscribes to analytics events from EventHorizon and processes them.

  Listens on "analytics:events" topic and broadcasts stats updates back.
  """

  use GenServer
  require Logger

  alias Accumulator.{Stats, Comments}

  @pubsub EventHorizon.PubSub
  @analytics_topic "analytics:events"

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Phoenix.PubSub.subscribe(@pubsub, @analytics_topic)
    Logger.info("Analytics subscriber started, listening on #{@analytics_topic}")
    {:ok, %{}}
  end

  @impl true
  def handle_info({:site_visit}, state) do
    Logger.debug("Received site visit")
    stat = Stats.increment_main_view_count()
    stats = %{visits: stat.views}
    Phoenix.PubSub.broadcast(@pubsub, "stats:site", {:site_stats_updated, stats})
    Phoenix.PubSub.broadcast(Accumulator.PubSub, "local:update:count", {:site_visit})
    {:noreply, state}
  end

  def handle_info({:blog_visit, slug}, state) do
    Logger.debug("Received blog visit for #{slug}")
    stat = Stats.increment_blog_view_count("blog:#{slug}")
    stats = build_blog_stats(slug, stat)
    broadcast_stats(slug, stats)
    Phoenix.PubSub.broadcast(Accumulator.PubSub, "local:update:count", {:blog_visit})
    {:noreply, state}
  end

  def handle_info({:blog_like, slug}, state) do
    Logger.debug("Received blog like for #{slug}")
    stat = Stats.increment_blog_like_count("blog:#{slug}")
    stats = build_blog_stats(slug, stat)
    broadcast_stats(slug, stats)
    {:noreply, state}
  end

  def handle_info({:blog_comment, slug, comment_data}, state) do
    Logger.debug("Received blog comment for #{slug}")
    %{content: content, author: author} = comment_data

    attrs = %{
      content: content,
      author: author,
      blog_slug: slug
    }

    case Comments.create_comment(attrs) do
      {:ok, comment} ->
        Task.Supervisor.start_child(Accumulator.TaskRunner, fn ->
          Accumulator.Mailer.send_comment_email(comment)
        end)

        stat = Stats.get_blog_data(slug) || %{views: 0, likes: 0}
        stats = build_blog_stats(slug, stat)
        broadcast_stats(slug, stats)

      {:error, _changeset} ->
        # TODO: handle this later
        nil
    end

    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warning("Unknown message received: #{inspect(msg)}")
    {:noreply, state}
  end

  defp build_blog_stats(slug, stat) do
    comments = Comments.list_comments_with_nested_replies(slug)

    %{
      visits: stat.views,
      likes: stat.likes,
      comments: comments
    }
  end

  defp broadcast_stats(slug, stats) do
    topic = "stats:blog:#{slug}"
    Phoenix.PubSub.broadcast(@pubsub, topic, {:stats_updated, stats})
    Logger.debug("Broadcasted stats update for #{slug}: #{inspect(stats)}")
  end
end
