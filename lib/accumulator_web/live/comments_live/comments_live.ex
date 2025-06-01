defmodule AccumulatorWeb.CommentsLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Comments

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Comments Dashboard")
     |> assign(:comments, [])
     |> assign(:selected_blog_slug, nil)
     |> assign(:blog_slugs, [])
     |> assign(:loading, false)
     |> assign(:delete_modal_open, false)
     |> assign(:comment_to_delete, nil)
     |> load_blog_slugs()
     |> load_all_comments()}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("filter_by_blog", %{"blog_slug" => ""}, socket) do
    {:noreply,
     socket
     |> assign(:selected_blog_slug, nil)
     |> load_all_comments()}
  end

  def handle_event("filter_by_blog", %{"blog_slug" => blog_slug}, socket) do
    {:noreply,
     socket
     |> assign(:selected_blog_slug, blog_slug)
     |> load_comments_for_blog(blog_slug)}
  end

  def handle_event("open_delete_modal", %{"comment_id" => comment_id}, socket) do
    comment = Comments.get_comment(comment_id)
    
    {:noreply,
     socket
     |> assign(:delete_modal_open, true)
     |> assign(:comment_to_delete, comment)}
  end

  def handle_event("close_delete_modal", _params, socket) do
    {:noreply,
     socket
     |> assign(:delete_modal_open, false)
     |> assign(:comment_to_delete, nil)}
  end

  def handle_event("delete_comment", %{"comment_id" => comment_id}, socket) do
    comment = Comments.get_comment(comment_id)
    
    case Comments.delete_comment(comment) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Comment deleted successfully")
         |> assign(:delete_modal_open, false)
         |> assign(:comment_to_delete, nil)
         |> refresh_comments()}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Failed to delete comment")
         |> assign(:delete_modal_open, false)
         |> assign(:comment_to_delete, nil)}
    end
  end

  def handle_event("refresh", _params, socket) do
    {:noreply, refresh_comments(socket)}
  end

  defp load_all_comments(socket) do
    assign(socket, :loading, true)
    # Get all comments and organize them hierarchically
    all_comments = Comments.get_all_comments()
    comments = organize_all_comments_hierarchy(all_comments)
    assign(socket, comments: comments, loading: false)
  end

  defp load_comments_for_blog(socket, blog_slug) do
    assign(socket, :loading, true)
    comments = Comments.list_comments_with_nested_replies(blog_slug)
    assign(socket, comments: comments, loading: false)
  end

  defp load_blog_slugs(socket) do
    blog_slugs = 
      Comments.get_all_comments()
      |> Enum.map(& &1.blog_slug)
      |> Enum.uniq()
      |> Enum.sort()
    
    assign(socket, :blog_slugs, blog_slugs)
  end

  defp refresh_comments(socket) do
    case socket.assigns.selected_blog_slug do
      nil -> load_all_comments(socket)
      blog_slug -> load_comments_for_blog(socket, blog_slug)
    end
    |> load_blog_slugs()
  end

  defp organize_all_comments_hierarchy(comments) do
    # Separate top-level comments and replies
    {top_level, replies} = Enum.split_with(comments, fn comment ->
      is_nil(comment.parent_id)
    end)

    # Create a map of replies by parent_id for quick lookup
    replies_map = Enum.group_by(replies, & &1.parent_id)

    # Attach replies to their parents
    top_level
    |> Enum.map(fn comment ->
      replies = Map.get(replies_map, comment.id, [])
      Map.put(comment, :replies, replies)
    end)
    |> Enum.sort_by(& &1.inserted_at, :desc)
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")
  end

  defp truncate_content(content, length) do
    if String.length(content) > length do
      String.slice(content, 0, length) <> "..."
    else
      content
    end
  end
end