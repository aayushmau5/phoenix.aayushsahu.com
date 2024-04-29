defmodule Accumulator.Notes do
  alias Accumulator.Notes.Note
  alias Accumulator.Repo
  import Ecto.Query

  # TODO: check if this is needed
  def get_by_ascending_order() do
    # TODO: Pagination?
    from(n in Note, order_by: [asc: n.id])
    |> Repo.all()
  end

  def get_notes_grouped_and_ordered_by_date(ending_date) do
    date_tuple = ending_date |> Date.add(1) |> Date.to_erl()

    ending_date_time =
      NaiveDateTime.from_erl!({date_tuple, {0, 0, 0}}) |> NaiveDateTime.truncate(:second)

    starting_date_time =
      NaiveDateTime.add(ending_date_time, -10, :day) |> NaiveDateTime.truncate(:second)

    # [ [date, [notes]], [date, [notes]] ]
    # TODO: think about how to store date
    result =
      from(n in Note,
        where: n.inserted_at >= ^starting_date_time,
        where: n.inserted_at <= ^ending_date_time,
        order_by: [asc: n.id]
      )
      |> Repo.all()
      |> group_and_sort_notes()

    {result, NaiveDateTime.to_date(starting_date_time)}
  end

  def get_notes_grouped_and_ordered_till_date(date) do
    date_tuple = date |> Date.add(1) |> Date.to_erl()

    date =
      NaiveDateTime.from_erl!({date_tuple, {0, 0, 0}}) |> NaiveDateTime.truncate(:second)

    from(n in Note,
      where: n.inserted_at >= ^date,
      order_by: [asc: n.id]
    )
    |> Repo.all()
    |> group_and_sort_notes()
  end

  def insert(changeset) do
    Repo.insert(changeset)
  end

  def update(id, params) do
    note = Repo.get(Note, id)
    changeset = Note.changeset(note, params) |> dbg()

    case Repo.update(changeset) do
      {:ok, note} -> note
      {:error, changeset} -> changeset
    end
  end

  def delete(id) do
    Repo.get!(Note, id)
    |> Repo.delete()
  end

  defp group_and_sort_notes(notes) do
    notes
    |> Enum.group_by(fn %{inserted_at: inserted_at} ->
      inserted_at |> NaiveDateTime.to_date() |> Date.to_string()
    end)
    |> Enum.map(fn {date, notes} -> [date, notes] end)
    |> Enum.sort_by(fn [date, _] -> date end)
  end
end
