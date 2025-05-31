defmodule Accumulator.Comments do
  import Ecto.Query
  alias Accumulator.{Comments.Comment, Repo}

  @doc """
  Gets a single comment by ID.
  """
  def get_comment(id) do
    Repo.get(Comment, id)
  end

  @doc """
  Gets a single comment by ID, raising an error if not found.
  """
  def get_comment!(id) do
    Repo.get!(Comment, id)
  end

  @doc """
  Lists all top-level comments for a specific blog slug.
  """
  def list_comments(blog_slug) do
    from(c in Comment,
      where: c.blog_slug == ^blog_slug and is_nil(c.parent_id),
      order_by: [desc: c.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Lists all replies to a specific comment.
  """
  def list_replies(parent_id) do
    from(c in Comment,
      where: c.parent_id == ^parent_id,
      order_by: [asc: c.inserted_at]
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
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an existing comment.
  """
  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
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
  Returns an `%Ecto.Changeset{}` for tracking comment changes.
  """
  def change_comment(%Comment{} = comment, attrs \\ %{}) do
    Comment.changeset(comment, attrs)
  end
end