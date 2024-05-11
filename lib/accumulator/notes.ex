defmodule Accumulator.Notes do
  alias Accumulator.Notes.{Note, Workspace}
  alias Accumulator.Repo
  import Ecto.Query

  def get_note_by_id(id) do
    Repo.get(Note, id)
  end

  def get_notes_grouped_and_ordered_by_date(workspace_id, ending_date) do
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
        where: n.workspace_id == ^workspace_id,
        order_by: [asc: n.id]
      )
      |> Repo.all()
      |> group_and_sort_notes()

    {result, NaiveDateTime.to_date(starting_date_time)}
  end

  def get_notes_grouped_and_ordered_till_date(workspace_id, date) do
    date_tuple = date |> Date.add(1) |> Date.to_erl()

    date =
      NaiveDateTime.from_erl!({date_tuple, {0, 0, 0}}) |> NaiveDateTime.truncate(:second)

    from(n in Note,
      where: n.inserted_at >= ^date,
      where: n.workspace_id == ^workspace_id,
      order_by: [asc: n.id]
    )
    |> Repo.all()
    |> group_and_sort_notes()
  end

  def insert(changeset) do
    Repo.insert(changeset)
  end

  def update_note(id, params) do
    note = Repo.get(Note, id)
    changeset = Note.changeset(note, params)

    Repo.insert(changeset,
      on_conflict: :replace_all,
      conflict_target: [:id]
    )
  end

  def delete_note(id) do
    Repo.get!(Note, id)
    |> Repo.delete()
  end

  def search_notes(workspace_id, search_term) do
    like = "%#{search_term}%"

    query =
      from(n in Note,
        where: like(n.text, ^like),
        where: n.workspace_id == ^workspace_id
      )

    Repo.all(query) |> group_and_sort_notes()
  end

  defp group_and_sort_notes(notes) do
    notes
    |> Enum.group_by(fn %{inserted_at: inserted_at} ->
      inserted_at |> NaiveDateTime.to_date() |> Date.to_string()
    end)
    |> Enum.map(fn {date, notes} -> [date, notes] end)
    |> Enum.sort_by(fn [date, _] -> date end)
  end

  # Workspace stuff

  # TODOs:
  # Handling pagination in workspace through dates while getting notes in a workspace

  def get_all_workspaces() do
    Repo.all(Workspace)
  end

  def get_workspace_by_id(id) do
    # Workspace or nil
    Repo.get(Workspace, id)
  end

  def create_new_workspace(params) do
    %Workspace{} |> Workspace.changeset(params) |> Repo.insert()
  end

  def rename_workspace(id, new_title) do
    # TODO: think about writing a query instead that changes the name without getting the workspace by its id first
    case get_workspace_by_id(id) do
      nil ->
        nil

      workspace ->
        updated_workspace_changeset = Workspace.changeset(workspace, %{title: new_title})
        Repo.update!(updated_workspace_changeset)
    end
  end

  def delete_workspace(id) do
    case get_workspace_by_id(id) do
      nil ->
        nil

      workspace ->
        Repo.delete(workspace)
    end
  end

  def create_note(workspace_id, note_params) do
    get_workspace_by_id(workspace_id)
    |> Ecto.build_assoc(:notes)
    |> Note.changeset(note_params)
    |> Repo.insert()
  end

  def update_note_workspace(note_id, workspace_id) do
    get_note_by_id(note_id)
    |> Note.changeset(%{workspace_id: workspace_id})
    |> Repo.update()
  end

  def get_notes_in_workspace(workspace_id) do
    from(n in Note, where: n.workspace_id == ^workspace_id, order_by: [asc: n.id])
    |> Repo.all()
  end

  # def assign_default_workspace_to_every_note() do
  #   from(n in Note, where: is_nil(n.workspace_id))
  #   |> Repo.all()
  #   |> Enum.map(fn n -> Note.changeset(n, %{workspace_id: 4}) |> Repo.update!() end)
  # end
end
