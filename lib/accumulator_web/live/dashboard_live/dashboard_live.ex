defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Stats}
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        PubSub.subscribe(Accumulator.PubSub, "update:count")

        main_stats = Stats.get_main_data()

        assign(socket,
          total_page_views: main_stats.views,
          current_page_view_count: get_presence_count("user-join"),
          blogs_data: generate_blog_data() |> sort_blog_data("slug", "asc")
        )
      else
        assign(socket, total_page_views: 0, blogs_data: [], current_page_view_count: 0)
      end

    {:ok,
     socket
     |> assign(page_title: "Dashboard", sort_key: "slug", sort_order: "asc")}
  end

  @impl true
  def handle_event("sort:" <> sort_key, _, socket),
    do: {:noreply, handle_sort_data_change(socket, sort_key)}

  @impl true
  def handle_info(%{event: :main_page_view_count}, socket) do
    main_stats = Stats.get_main_data()
    {:noreply, assign(socket, total_page_views: main_stats.views)}
  end

  @impl true
  def handle_info(%{event: :blog_page_view_count, key: _slug}, socket) do
    blogs_data = generate_blog_data()

    {:noreply,
     assign(socket,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  @impl true
  def handle_info(%{event: :blog_like_count, key: _slug}, socket) do
    blogs_data = generate_blog_data()

    {:noreply,
     assign(socket,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  @impl true
  def handle_info(%{event: :main_page_user_count}, socket) do
    {:noreply, assign(socket, current_page_view_count: get_presence_count("user-join"))}
  end

  @impl true
  def handle_info(%{event: :blog_page_user_count, key: _key}, socket) do
    blogs_data = generate_blog_data()

    {:noreply,
     assign(socket,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  defp generate_blog_data() do
    Stats.get_all_blogs_data() |> insert_presence_count()
  end

  defp insert_presence_count(blogs) do
    Enum.map(blogs, fn blog ->
      presence_count = get_presence_count(blog.slug)
      Stats.update_current_viewing_value(blog, presence_count)
    end)
  end

  defp get_presence_count(key) do
    Presence.list(key)
    |> Map.get(key, %{metas: []})
    |> Map.get(:metas)
    |> length()
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
