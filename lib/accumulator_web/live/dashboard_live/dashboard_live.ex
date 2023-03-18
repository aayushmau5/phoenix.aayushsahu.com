defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.BlogData
  alias AccumulatorWeb.Presence
  alias Accumulator.Storage.{LikesCount, ViewCount}
  alias Phoenix.PubSub

  @impl true
  def mount(_params, _session, socket) do
    socket =
      if connected?(socket) do
        PubSub.subscribe(Accumulator.PubSub, "update:count")

        assign(socket,
          total_page_views: Accumulator.get_total_website_views(),
          current_page_view_count: get_presence_count("user-join"),
          # TODO: think about putting this data in a stream
          blogs_data: generate_blog_data() |> sort_blog_data("id", "asc")
        )
      else
        assign(socket, total_page_views: 0, blogs_data: [], current_page_view_count: 0)
      end

    {:ok,
     socket
     |> assign(page_title: "Dashboard", sort_key: "id", sort_order: "asc")}
  end

  @impl true
  def handle_event("sort:" <> sort_key, _, socket),
    do: {:noreply, handle_sort_data_change(socket, sort_key)}

  @impl true
  def handle_info(%{event: :main_page_view_count}, socket) do
    {:noreply, assign(socket, total_page_views: Accumulator.get_total_website_views())}
  end

  @impl true
  def handle_info(%{event: :blog_page_view_count, key: "blog:" <> id}, socket) do
    blogs_data = socket.assigns.blogs_data
    blog_index = Enum.find_index(blogs_data, &(Map.get(&1, :id) == id))

    blogs_data =
      case blog_index do
        nil ->
          # Key doesn't exist, a new blog data. Get all data.
          generate_blog_data()

        index ->
          # Key exists, update its view count.
          blog_view_count = ViewCount.get_count("blog:" <> id)

          List.update_at(blogs_data, index, fn blog ->
            Map.update!(blog, :views, fn _ -> blog_view_count end)
          end)
      end

    {:noreply,
     assign(socket,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  @impl true
  def handle_info(%{event: :blog_like_count, key: "blog:" <> id}, socket) do
    blogs_data = socket.assigns.blogs_data
    blog_index = Enum.find_index(blogs_data, &(Map.get(&1, :id) == id))
    blog_likes_count = LikesCount.get_count("like-blog:" <> id)

    # We assume key exists(because you can't like a blog without opening it, thus changing its view count).
    blogs_data =
      List.update_at(blogs_data, blog_index, fn blog ->
        Map.update!(blog, :likes, fn _ -> blog_likes_count end)
      end)

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
  def handle_info(%{event: :blog_page_user_count, key: key}, socket) do
    blogs_data = socket.assigns.blogs_data
    "blog:" <> id = key
    blog_index = Enum.find_index(blogs_data, &(Map.get(&1, :id) == id))

    blogs_data =
      case blog_index do
        nil ->
          # not sure if key should already exist or not
          generate_blog_data()

        index ->
          # Key exists, update its view count.
          List.update_at(blogs_data, index, fn blog ->
            Map.update!(blog, :current_viewing, fn _ -> get_presence_count(key) end)
          end)
      end

    {:noreply,
     assign(socket,
       blogs_data: sort_blog_data(blogs_data, socket.assigns.sort_key, socket.assigns.sort_order)
     )}
  end

  defp generate_blog_data(), do: Accumulator.generate_blog_data() |> insert_presence_count()

  defp insert_presence_count(blogs) do
    Enum.map(blogs, fn blog ->
      presence_count = get_presence_count("blog:" <> blog.id)
      BlogData.update_current_viewing_value(blog, presence_count)
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
