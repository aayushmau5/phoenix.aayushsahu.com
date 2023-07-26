defmodule Accumulator.Stats do
  import Ecto.Query
  alias Accumulator.{Stats.Stat, Repo}

  # Main
  def get_main_data() do
    get_stat("main")
  end

  def increment_main_view_count() do
    case increment_views("main") do
      {0, []} ->
        {:ok, stat} = insert_stat("main")
        stat

      {_, [%Stat{} = stat]} ->
        stat
    end
  end

  # Blogs

  def get_blog_data(slug) do
    get_stat(slug)
  end

  def increment_blog_view_count(slug) do
    case increment_views(slug) do
      {0, []} ->
        {:ok, stat} = insert_stat(slug)
        stat

      {_, [%Stat{} = stat]} ->
        stat
    end
  end

  def increment_blog_like_count(slug) do
    case increment_likes(slug) do
      {0, []} ->
        {:ok, stat} = insert_stat(slug)
        stat

      {_, [%Stat{} = stat]} ->
        stat
    end
  end

  def get_all_blogs_data() do
    from(stat in Stat, where: like(stat.slug, "blog:%"), select: stat)
    |> Repo.all()
  end

  def update_current_viewing_value(stat, value) do
    Map.put(stat, :current_viewing, value)
  end

  defp get_stat(slug) do
    Repo.one(from(stat in Stat, where: stat.slug == ^slug))
  end

  defp increment_views(slug) do
    from(stat in Stat,
      where: stat.slug == ^slug,
      update: [inc: [views: 1], set: [updated_at: ^DateTime.utc_now()]],
      select: stat
    )
    |> Repo.update_all([])
  end

  defp increment_likes(slug) do
    from(stat in Stat,
      where: stat.slug == ^slug,
      update: [inc: [likes: 1], set: [updated_at: ^DateTime.utc_now()]],
      select: stat
    )
    |> Repo.update_all([])
  end

  defp insert_stat(slug) do
    Repo.insert(%Stat{slug: slug})
  end
end
