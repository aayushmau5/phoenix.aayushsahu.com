defmodule Accumulator do
  @moduledoc """
  Accumulator keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  @spec get_total_website_views() :: atom() | integer()
  def get_total_website_views() do
    case Redix.command(:redix, ["GET", "main"]) do
      {:ok, count} -> count
      # TODO: handle this error
      {:error, reason} -> reason
    end
  end

  @spec generate_blog_data() :: list(map())
  @doc """
  Generates blog data in sorted order of their view count.
  """
  def generate_blog_data() do
    {:ok, keys} = get_blog_keys()

    Enum.map(keys, &generate_single_blog_data(&1))
    # Sort by view count
    # TODO: implement sort based on user input
    |> Enum.sort(&(&1.views > &2.views))
  end

  # TODO: need a better data structure
  defp generate_single_blog_data(key) do
    "blog:" <> slug = key

    case Redix.command(:redix, ["MGET", key, "like-" <> key]) do
      {:ok, [views, nil]} ->
        %{
          key: slug,
          views: String.to_integer(views),
          likes_count: 0
        }

      {:ok, [views, likes]} ->
        %{
          key: slug,
          views: String.to_integer(views),
          likes_count: String.to_integer(likes)
        }

      {:error, reason} ->
        # TODO: handle error
        throw(reason)
    end
  end

  defp get_blog_keys() do
    Redix.command(:redix, ["KEYS", "blog:*"])
  end
end
