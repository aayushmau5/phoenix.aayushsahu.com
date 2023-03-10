defmodule Accumulator do
  @moduledoc """
  Accumulator keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  alias Accumulator.Storage.{LikesCount, ViewCount}
  alias AccumulatorWeb.Presence

  @spec get_total_website_views() :: atom() | integer()
  def get_total_website_views() do
    case Redix.command(:redix, ["GET", "main"]) do
      {:ok, count} -> count
      {:error, reason} -> reason
    end
  end

  @spec generate_blog_data() :: list(map())
  @doc """
  Generates blog data in sorted order of their view count.
  """
  def generate_blog_data() do
    {:ok, keys} = get_blog_keys()

    Enum.map(keys, fn key ->
      "blog:" <> slug = key

      %{
        key: slug,
        views: ViewCount.get_count(key),
        likes_count: LikesCount.get_count("like-blog:" <> slug),
        # This thing doesn't really belong here
        current_view_count:
          Presence.list(key) |> Map.get("", %{metas: []}) |> Map.get(:metas) |> length()
      }
    end)
    |> Enum.sort(&(&1.views > &2.views))
  end

  defp get_blog_keys() do
    Redix.command(:redix, ["KEYS", "blog:*"])
  end
end
