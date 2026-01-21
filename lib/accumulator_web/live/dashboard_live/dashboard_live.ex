defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Stats, Comments}
  alias PubSubContract.Bus
  alias EhaPubsubMessages.Presence
  alias Accumulator.PubSub.Messages.Local

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        # Subscribe to presence updates from EventHorizon
        Bus.subscribe(EventHorizon.PubSub, Presence.SitePresence)
        Bus.subscribe(EventHorizon.PubSub, Presence.BlogPresence)

        # Subscribe to local updates
        Bus.subscribe(Accumulator.PubSub, Local.SiteVisit)

        # Request current presence counts from remote nodes
        Bus.publish(EventHorizon.PubSub, Presence.PresenceRequest.new!(type: :site))
        Bus.publish(EventHorizon.PubSub, Presence.PresenceRequest.new!(type: :blog))

        main_stats = Stats.get_main_data()

        assign(socket,
          total_page_views: main_stats.views,
          current_viewing: 0,
          blog_presence: %{},
          blogs_data: generate_blog_data(%{}) |> sort_blog_data("slug", "asc"),
          battleship: Stats.get_blog_data("battleship").views
        )
      else
        assign(socket,
          total_page_views: 0,
          blogs_data: [],
          current_viewing: 0,
          blog_presence: %{},
          battleship: 0
        )
      end

    {:ok,
     socket
     |> assign(page_title: "Dashboard", sort_key: "slug", sort_order: "asc")}
  end

  @impl true
  def handle_event("sort:" <> sort_key, _, socket),
    do: {:noreply, handle_sort_data_change(socket, sort_key)}

  # Handle site presence updates from EventHorizon
  @impl true
  def handle_info(%Presence.SitePresence{count: count}, socket) do
    {:noreply, assign(socket, current_viewing: count)}
  end

  # Handle blog presence updates from EventHorizon
  def handle_info(%Presence.BlogPresence{slug: slug, count: count}, socket) do
    blog_presence = Map.put(socket.assigns.blog_presence, "blog:#{slug}", count)
    blogs_data = generate_blog_data(blog_presence)

    {:noreply,
     assign(socket,
       blog_presence: blog_presence,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  def handle_info(%Local.SiteVisit{}, socket) do
    main_stats = Stats.get_main_data()
    {:noreply, assign(socket, total_page_views: main_stats.views)}
  end

  def handle_info(%Local.BlogVisit{}, socket) do
    blogs_data = generate_blog_data(socket.assigns.blog_presence)
    {:noreply, assign(socket, blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order))}
  end

  def handle_info(_msg, socket), do: {:noreply, socket}

  defp generate_blog_data(blog_presence) do
    Stats.get_all_blogs_data() |> insert_presence_count(blog_presence)
  end

  defp insert_presence_count(blogs, blog_presence) do
    Enum.map(blogs, fn blog ->
      # blog.slug already has "blog:" prefix, and blog_presence keys also have "blog:" prefix
      presence_count = Map.get(blog_presence, blog.slug, 0)
      # Comments use slug without "blog:" prefix
      blog_slug = String.replace_prefix(blog.slug, "blog:", "")
      comment_count = Comments.count_comments(blog_slug)

      blog
      |> Stats.update_current_viewing_value(presence_count)
      |> Map.put(:comments, comment_count)
    end)
  end

  defp handle_sort_data_change(socket, sort_key_to_match) do
    case socket.assigns do
      %{sort_key: ^sort_key_to_match, sort_order: "asc"} = _ ->
        assign(socket,
          sort_order: "desc",
          blogs_data: sort_blog_data(socket.assigns.blogs_data, sort_key_to_match, "desc")
        )

      %{sort_key: ^sort_key_to_match, sort_order: "desc"} = _ ->
        assign(socket,
          sort_order: "asc",
          blogs_data: sort_blog_data(socket.assigns.blogs_data, sort_key_to_match, "asc")
        )

      _ ->
        assign(socket,
          sort_key: sort_key_to_match,
          sort_order: "asc",
          blogs_data: sort_blog_data(socket.assigns.blogs_data, sort_key_to_match, "asc")
        )
    end
  end

  defp sort_blog_data(data, sort_key, sort_order) do
    sort_key = String.to_atom(sort_key)

    if sort_order == "asc" do
      Enum.sort(data, &(Map.get(&1, sort_key) <= Map.get(&2, sort_key)))
    else
      Enum.sort(data, &(Map.get(&1, sort_key) >= Map.get(&2, sort_key)))
    end
  end
end
