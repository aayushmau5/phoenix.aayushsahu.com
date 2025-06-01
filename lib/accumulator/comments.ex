defmodule Accumulator.Comments do
  import Ecto.Query
  alias Accumulator.{Comments.Comment, Repo}

  def get_all_comments() do
    Repo.all(Comment)
  end

  @doc """
  Gets a single comment by ID.
  """
  def get_comment(id) do
    case Repo.get(Comment, id) do
      nil -> nil
      comment -> Repo.preload(comment, :replies)
    end
  end

  @doc """
  Gets a single comment by ID, raising an error if not found.
  """
  def get_comment!(id) do
    Repo.get!(Comment, id)
    |> Repo.preload(:replies)
  end

  @doc """
  Lists all top-level comments for a specific blog slug.
  """
  def list_comments(blog_slug) do
    from(c in Comment,
      where: c.blog_slug == ^blog_slug and is_nil(c.parent_id),
      order_by: [desc: c.inserted_at],
      preload: [:replies]
    )
    |> Repo.all()
  end

  @doc """
  Lists all replies to a specific comment.
  """
  def list_replies(parent_id) do
    from(c in Comment,
      where: c.parent_id == ^parent_id,
      order_by: [asc: c.inserted_at],
      preload: [:replies]
    )
    |> Repo.all()
  end

  @doc """
  Gets all comments for a blog with their replies in a nested structure.
  """
  def list_comments_with_replies(blog_slug) do
    comments = list_comments(blog_slug)

    Enum.map(comments, fn comment ->
      replies = list_replies(comment.id)
      Map.put(comment, :replies, replies)
    end)
  end

  @doc """
  Creates a new comment.
  """
  def create_comment(attrs \\ %{}) do
    case %Comment{}
         |> Comment.changeset(attrs)
         |> Repo.insert() do
      {:ok, comment} ->
        {:ok, Repo.preload(comment, :replies)}

      error ->
        error
    end
  end

  @doc """
  Updates an existing comment.
  """
  def update_comment(%Comment{} = comment, attrs) do
    case comment
         |> Comment.changeset(attrs)
         |> Repo.update() do
      {:ok, comment} ->
        {:ok, Repo.preload(comment, :replies)}

      error ->
        error
    end
  end

  @doc """
  Deletes a comment and all its replies (cascading delete).
  """
  def delete_comment(%Comment{} = comment) do
    Repo.delete(comment)
  end

  @doc """
  Returns the count of comments for a specific blog.
  """
  def count_comments(blog_slug) do
    from(c in Comment, where: c.blog_slug == ^blog_slug, select: count(c.id))
    |> Repo.one()
  end

  @doc """
  Gets all comments for a blog with deeply nested replies loaded.
  This is more efficient than the previous list_comments_with_replies function.
  """
  def list_comments_with_nested_replies(blog_slug) do
    # Get all comments for this blog (both top-level and replies)
    all_comments =
      from(c in Comment,
        where: c.blog_slug == ^blog_slug,
        order_by: [asc: c.inserted_at]
      )
      |> Repo.all()

    # Organize them into a nested structure
    organize_comments_hierarchy(all_comments)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end

  # Private helper to organize flat comment list into nested hierarchy
  defp organize_comments_hierarchy(comments) do
    # Create a map for quick lookup
    comment_map =
      Enum.reduce(comments, %{}, fn comment, acc ->
        Map.put(acc, comment.id, Map.put(comment, :replies, []))
      end)

    # Separate top-level comments and replies
    {top_level, replies} =
      Enum.split_with(comments, fn comment ->
        is_nil(comment.parent_id)
      end)

    # Attach replies to their parents
    comment_map_with_replies =
      Enum.reduce(replies, comment_map, fn reply, acc ->
        case Map.get(acc, reply.parent_id) do
          # Parent not found
          nil ->
            acc

          parent ->
            updated_parent =
              Map.update!(parent, :replies, fn existing_replies ->
                [Map.get(acc, reply.id) | existing_replies]
              end)

            Map.put(acc, reply.parent_id, updated_parent)
        end
      end)

    # Return top-level comments with their replies attached
    Enum.map(top_level, fn comment ->
      Map.get(comment_map_with_replies, comment.id)
    end)
    # Most recent first
    |> Enum.reverse()
  end
end
