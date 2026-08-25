defmodule Accumulator.PubSub.Messages.Comments.Changed do
  @moduledoc """
  Broadcast when a comment or reply is created, updated, or deleted.
  """

  use PubSubContract.Message

  message do
    field(:type, :atom, required: true)
    field(:blog_slug, :string, required: true)
    field(:comment_id, :integer, required: true)
  end

  @impl true
  def topic, do: "comments:changed"

  @impl true
  def validate(%__MODULE__{type: type, blog_slug: blog_slug, comment_id: comment_id})
      when type in [:created, :updated, :deleted] and is_binary(blog_slug) and
             is_integer(comment_id),
      do: :ok

  def validate(_message), do: {:error, :invalid_payload}
end
