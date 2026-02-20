defmodule Accumulator.Analytics.Subscriber do
  @moduledoc """
  Subscribes to analytics events from EventHorizon and processes them.
  Listens on "analytics:events" topic and broadcasts stats updates back.
  """

  use GenServer
  require Logger

  alias Accumulator.{Stats, Comments}
  alias PubSubContract.Bus
  alias EhaPubsubMessages.{Analytics, Stats, Topics}
  alias Accumulator.PubSub.Messages.Local

  @pubsub EventHorizon.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Bus.subscribe(@pubsub, Analytics.SiteVisit)
    Logger.info("Analytics subscriber started, listening on #{Analytics.SiteVisit.topic()}")
    {:ok, %{}}
  end

  @impl true
  def handle_info(%Analytics.SiteStatRequest{}, state) do
    Logger.debug("Received site stats request")
    stat = Accumulator.Stats.get_main_data()
    Bus.publish(@pubsub, Stats.SiteUpdated.new!(visits: stat.views))
    {:noreply, state}
  end

  def handle_info(%Analytics.BlogStatRequest{slug: slug}, state) do
    Logger.debug("Received blog stats request")
    stat = Accumulator.Stats.get_blog_data("blog:#{slug}")
    broadcast_blog_stats(slug, stat)
    {:noreply, state}
  end

  def handle_info(%Analytics.SiteVisit{user_agent: user_agent}, state) do
    Logger.debug("Received site visit")

    stat = Accumulator.Stats.increment_main_view_count()

    if user_agent do
      parsed_ua = Accumulator.Analytics.UA.parse(user_agent)
      Accumulator.Stats.increment_daily_user_agent(parsed_ua)
    end

    Bus.publish(@pubsub, Stats.SiteUpdated.new!(visits: stat.views))
    Bus.publish(Accumulator.PubSub, %Local.SiteVisit{})
    {:noreply, state}
  end

  def handle_info(%Analytics.BlogVisit{slug: slug}, state) do
    Logger.debug("Received blog visit for #{slug}")
    stat = Accumulator.Stats.increment_blog_view_count("blog:#{slug}")
    broadcast_blog_stats(slug, stat)
    Bus.publish(Accumulator.PubSub, %Local.BlogVisit{})
    {:noreply, state}
  end

  def handle_info(%Analytics.BlogLike{slug: slug}, state) do
    Logger.debug("Received blog like for #{slug}")
    stat = Accumulator.Stats.increment_blog_like_count("blog:#{slug}")
    broadcast_blog_stats(slug, stat)
    {:noreply, state}
  end

  def handle_info(
        %Analytics.BlogComment{
          slug: slug,
          content: content,
          author: author,
          parent_id: parent_id
        },
        state
      ) do
    Logger.debug("Received blog comment for #{slug}")

    attrs = %{
      content: content,
      author: author,
      blog_slug: slug,
      parent_id: parent_id
    }

    case Comments.create_comment(attrs) do
      {:ok, comment} ->
        Task.Supervisor.start_child(Accumulator.TaskRunner, fn ->
          Accumulator.Mailer.send_comment_email(comment)
        end)

        stat = Accumulator.Stats.get_blog_data("blog:#{slug}") || %{views: 0, likes: 0}
        broadcast_blog_stats(slug, stat)

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

  defp broadcast_blog_stats(slug, stat) do
    comments = Comments.list_comments_with_nested_replies(slug)
    topic = Topics.blog_stats(slug: slug)

    Bus.publish(
      @pubsub,
      Stats.BlogUpdated.new!(
        slug: slug,
        visits: stat.views,
        likes: stat.likes,
        comments: comments
      ),
      topic: topic
    )

    Logger.debug("Broadcasted stats update for #{slug}")
  end
end
