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

  def insert(params) do
    changeset = Note.changeset(%Note{}, params)

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
