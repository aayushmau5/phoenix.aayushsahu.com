defmodule Accumulator.Notes do
  alias Accumulator.Notes.Note
  alias Accumulator.Repo
  import Ecto.Query

  def get_by_ascending_order() do
    # TODO: Pagination?
    from(n in Note, order_by: [asc: n.id])
    |> Repo.all()
  end

  def get_by_descending_order() do
    # TODO: Pagination?
    from(n in Note, order_by: [desc: n.id])
    |> Repo.all()
  end

  def fake_insert(date) do
    %Note{files: [], text: "meowwww", inserted_at: date, updated_at: date}
    |> Repo.insert!()
  end

  # TODO: implement the strucutre of data in application layer
  def implementation() do
    # life would start becoming better if i just focus and control myself
    # controlling myself is the ultimate test of mind

    {date_tuple, _} = :calendar.local_time()
    ending_date_time = NaiveDateTime.from_erl!({date_tuple, {0, 0, 0}})

    starting_date_time =
      NaiveDateTime.add(ending_date_time, -10, :day) |> NaiveDateTime.truncate(:second)

    result =
      from(n in Note, where: n.inserted_at >= ^starting_date_time, order_by: [desc: n.id])
      |> Repo.all()
      |> Enum.reduce(%{dates: []}, fn note, acc ->
        string_date = note.inserted_at |> NaiveDateTime.to_date() |> Date.to_string()
        grouped_data = Map.get(acc, string_date, [])
        grouped_data = grouped_data ++ [note]
        acc = Map.put(acc, string_date, grouped_data)

        dates = Map.get(acc, :dates)

        dates =
          if Enum.member?(dates, string_date),
            do: dates,
            else: dates ++ [string_date]

        Map.put(acc, :dates, dates)
      end)

    {result, starting_date_time}
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
    Repo.get(Note, id)
    |> Repo.delete()
  end
end
