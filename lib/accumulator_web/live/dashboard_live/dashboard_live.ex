defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view

  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.{LikesCount, ViewCount}
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    # TODO: better assign naming
    socket =
      if connected?(socket) do
        PubSub.subscribe(Accumulator.PubSub, "update:count")

        assign(socket,
          total_page_views: Accumulator.get_total_website_views(),
          current_page_view_count: get_presence_count("user-join"),
          # TODO: think about putting this data in a stream
          blogs_data: generate_blog_data()
        )
      else
        assign(socket, total_page_views: 0, blogs_data: [], current_page_view_count: 0)
      end

    {:ok,
     socket
     |> assign(page_title: "Dashboard")}
  end

  @impl true
  def handle_info(%{event: :main_page_view_count}, socket) do
    {:noreply, assign(socket, total_page_views: Accumulator.get_total_website_views())}
  end

  @impl true
  def handle_info(%{event: :blog_page_view_count, key: "blog:" <> key}, socket) do
    blogs_data = socket.assigns.blogs_data

    blog_index =
      blogs_data
      |> Enum.find_index(&(Map.get(&1, :key) == key))

    blogs_data =
      case blog_index do
        nil ->
          # Key doesn't exist, a new blog data. Get all data.
          generate_blog_data()

        index ->
          # Key exists, update its view count.
          blog_view_count = ViewCount.get_count("blog:" <> key)

          List.update_at(blogs_data, index, fn map ->
            Map.update!(map, :views, fn _ -> blog_view_count end)
          end)
      end

    {:noreply, assign(socket, blogs_data: blogs_data)}
  end

  @impl true
  def handle_info(%{event: :blog_like_count, key: "blog:" <> key}, socket) do
    blogs_data = socket.assigns.blogs_data

    blog_index =
      blogs_data
      |> Enum.find_index(&(Map.get(&1, :key) == key))

    blog_likes_count = LikesCount.get_count("like-blog:" <> key)

    # We assume key exists(because you can't like a blog without opening it, thus changing its view count).
    blogs_data =
      List.update_at(blogs_data, blog_index, fn map ->
        Map.update!(map, :likes_count, fn _ -> blog_likes_count end)
      end)

    {:noreply, assign(socket, blogs_data: blogs_data)}
  end

  @impl true
  def handle_info(%{event: :main_page_user_count}, socket) do
    {:noreply, assign(socket, current_page_view_count: get_presence_count("user-join"))}
  end

  @impl true
  def handle_info(%{event: :blog_page_user_count, key: key}, socket) do
    blogs_data = socket.assigns.blogs_data

    "blog:" <> slug = key

    blog_index =
      blogs_data
      |> Enum.find_index(&(Map.get(&1, :key) == slug))

    blogs_data =
      case blog_index do
        nil ->
          # not sure if key should already exist or not
          generate_blog_data()

        index ->
          # Key exists, update its view count.
          List.update_at(blogs_data, index, fn map ->
            Map.update!(map, :current_view_count, fn _ -> get_presence_count(key) end)
          end)
      end

    {:noreply, assign(socket, blogs_data: blogs_data)}
  end

  defp generate_blog_data(), do: Accumulator.generate_blog_data() |> insert_presence_count()

  defp insert_presence_count(blogs) do
    Enum.map(blogs, fn blog ->
      presence_count = get_presence_count("blog:" <> blog.key)
      Map.put(blog, :current_view_count, presence_count)
    end)
  end

  defp get_presence_count(key) do
    Presence.list(key)
    |> Map.get(key, %{metas: []})
    |> Map.get(:metas)
    |> length()
  end
end
