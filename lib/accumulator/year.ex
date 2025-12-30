defmodule Accumulator.Year do
  import Ecto.Query
  alias Accumulator.Repo
  alias Accumulator.Year.Log

  @doc """
  Returns all logs for a given year.
  """
  def list_logs(year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    from(l in Log,
      where: l.logged_on >= ^start_date and l.logged_on <= ^end_date,
      order_by: [asc: l.logged_on]
    )
    |> Repo.all()
  end

  @doc """
  Gets a log by date.
  """
  def get_log_by_date(date) do
    Repo.get_by(Log, logged_on: date)
  end

  @doc """
  Gets a log by id.
  """
  def get_log(id) do
    Repo.get(Log, id)
  end

  @doc """
  Creates a log entry.
  """
  def create_log(attrs \\ %{}) do
    %Log{}
    |> Log.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a log entry.
  """
  def update_log(%Log{} = log, attrs) do
    log
    |> Log.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a log entry.
  """
  def delete_log(%Log{} = log) do
    Repo.delete(log)
  end

  @doc """
  Returns a changeset for tracking log changes.
  """
  def change_log(%Log{} = log, attrs \\ %{}) do
    Log.changeset(log, attrs)
  end

  @doc """
  Returns a set of dates that have logs for a given year.
  """
  def logged_dates(year) do
    start_date = Date.new!(year, 1, 1)
    end_date = Date.new!(year, 12, 31)

    from(l in Log,
      where: l.logged_on >= ^start_date and l.logged_on <= ^end_date,
      select: l.logged_on
    )
    |> Repo.all()
    |> MapSet.new()
  end
end
