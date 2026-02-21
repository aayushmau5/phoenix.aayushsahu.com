defmodule Accumulator.Stats do
  import Ecto.Query
  alias Accumulator.{Stats.Stat, Stats.DailyStat, Stats.DailyUserAgentStat, Repo}

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

  # Daily Stats

  def get_daily_stats(slug, start_date, end_date) do
    from(ds in DailyStat,
      where: ds.slug == ^slug and ds.date >= ^start_date and ds.date <= ^end_date,
      order_by: [asc: ds.date]
    )
    |> Repo.all()
  end

  def get_daily_stats_for_last_n_days(slug, days) do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -(days - 1))
    get_daily_stats(slug, start_date, end_date)
  end

  defp get_stat(slug) do
    Repo.one(from(stat in Stat, where: stat.slug == ^slug))
  end

  defp increment_views(slug) do
    increment_daily_views(slug)

    from(stat in Stat,
      where: stat.slug == ^slug,
      update: [inc: [views: 1], set: [updated_at: ^DateTime.utc_now()]],
      select: stat
    )
    |> Repo.update_all([])
  end

  defp increment_likes(slug) do
    increment_daily_likes(slug)

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

  defp increment_daily_views(slug) do
    today = Date.utc_today()

    Repo.insert(
      %DailyStat{slug: slug, date: today, views: 1, likes: 0},
      on_conflict: [inc: [views: 1], set: [updated_at: DateTime.utc_now()]],
      conflict_target: [:slug, :date]
    )
  end

  def get_user_agent_stats() do
    from(s in DailyUserAgentStat,
      group_by: [s.browser, s.os, s.device],
      select: %{browser: s.browser, os: s.os, device: s.device, count: sum(s.count)},
      order_by: [desc: sum(s.count)]
    )
    |> Repo.all()
  end

  def increment_daily_user_agent(%{browser: browser, os: os, device: device}) do
    today = Date.utc_today()

    Repo.insert(
      %DailyUserAgentStat{date: today, browser: browser, os: os, device: device, count: 1},
      on_conflict: [inc: [count: 1], set: [updated_at: DateTime.utc_now()]],
      conflict_target: [:date, :browser, :os, :device]
    )
  end

  defp increment_daily_likes(slug) do
    today = Date.utc_today()

    Repo.insert(
      %DailyStat{slug: slug, date: today, views: 0, likes: 1},
      on_conflict: [inc: [likes: 1], set: [updated_at: DateTime.utc_now()]],
      conflict_target: [:slug, :date]
    )
  end
end
