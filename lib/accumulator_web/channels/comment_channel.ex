defmodule AccumulatorWeb.CommentChannel do
  use Phoenix.Channel

  alias Accumulator.Comments
  alias Phoenix.PubSub

  @pubsub Accumulator.PubSub

  @impl true
  def join("comments:" <> blog_slug, _params, socket) do
    socket = assign(socket, :blog_slug, blog_slug)
    send(self(), :after_join)
    {:ok, socket}
  end

  @impl true
  def handle_info(:after_join, socket) do
    blog_slug = socket.assigns.blog_slug

    # Send initial comments to the user
    comments = Comments.list_comments_with_nested_replies(blog_slug)
    push(socket, "comments_loaded", %{comments: serialize_comments(comments)})

    # Subscribe to comment updates for this blog
    PubSub.subscribe(@pubsub, "comments:#{blog_slug}")

    {:noreply, socket}
  end

  # @impl true
  # def handle_info(%{event: :comment_created, comment: comment}, socket) do
  #   # comments = Comments.list_comments_with_nested_replies(comment.blog_slug)
  #   # push(socket, "comments_loaded", %{comments: serialize_comments(comments)})
  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info(%{event: :reply_created, reply: reply}, socket) do
  #   push(socket, "reply_created", %{reply: serialize_comment(reply)})
  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info(%{event: :comment_deleted, comment_id: comment_id}, socket) do
  #   push(socket, "comment_deleted", %{comment_id: comment_id})
  #   {:noreply, socket}
  # end

  @impl true
  def handle_in("new_comment", %{"content" => content, "author" => author}, socket) do
    blog_slug = socket.assigns.blog_slug

    attrs = %{
      content: content,
      author: author,
      blog_slug: blog_slug
    }

    case Comments.create_comment(attrs) do
      {:ok, _comment} ->
        # Broadcast to all users in this blog's comment channel
        comments = Comments.list_comments_with_nested_replies(blog_slug)
        push(socket, "comments_loaded", %{comments: serialize_comments(comments)})

        # Also broadcast via PubSub for other potential listeners
        # PubSub.broadcast(@pubsub, "comments:#{blog_slug}", %{
        #   event: :comment_created,
        #   comment: comment
        # })

        {:reply, {:ok, nil}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in(
        "new_reply",
        %{"content" => content, "author" => author, "parent_id" => parent_id},
        socket
      ) do
    blog_slug = socket.assigns.blog_slug

    attrs = %{
      content: content,
      author: author,
      blog_slug: blog_slug,
      parent_id: parent_id
    }

    case Comments.create_comment(attrs) do
      {:ok, comment} ->
        # Broadcast to all users in this blog's comment channel
        comments = Comments.list_comments_with_nested_replies(blog_slug)
        push(socket, "comments_loaded", %{comments: serialize_comments(comments)})

        # Also broadcast via PubSub
        # PubSub.broadcast(@pubsub, "comments:#{blog_slug}", %{
        #   event: :reply_created,
        #   reply: comment
        # })

        {:reply, {:ok, %{reply: serialize_comment(comment)}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
    end
  end

  @impl true
  def handle_in("delete_comment", %{"comment_id" => comment_id}, socket) do
    case Comments.get_comment(comment_id) do
      nil ->
        {:reply, {:error, %{message: "Comment not found"}}, socket}

      comment ->
        case Comments.delete_comment(comment) do
          {:ok, _} ->
            broadcast!(socket, "comment_deleted", %{comment_id: comment_id})

            # PubSub.broadcast(@pubsub, "comments:#{blog_slug}", %{
            #   event: :comment_deleted,
            #   comment_id: comment_id
            # })

            {:reply, {:ok, %{comment_id: comment_id}}, socket}

          {:error, changeset} ->
            {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
        end
    end
  end

  # Private helper functions

  defp serialize_comments(comments) do
    Enum.map(comments, &serialize_comment/1)
  end

  defp serialize_comment(%Comments.Comment{} = comment) do
    %{
      id: comment.id,
      content: comment.content,
      author: comment.author || "Anonymous",
      blog_slug: comment.blog_slug,
      parent_id: comment.parent_id,
      inserted_at: comment.inserted_at,
      updated_at: comment.updated_at,
      replies: serialize_replies(comment.replies)
    }
  end

  defp serialize_replies(replies) do
    Enum.map(replies, &serialize_comment/1)
  end

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
