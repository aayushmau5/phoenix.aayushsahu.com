defmodule Accumulator.Notes do
  alias Accumulator.Notes.{Note, Workspace}
  alias Accumulator.{Repo, Helpers}
  import Ecto.Query

  @pubsub Accumulator.PubSub
  @pubsub_topic "notes-pubsub-event"

  def get_note_by_id(id) do
    Repo.get!(Note, id)
  end

  def get_notes_grouped_and_ordered_by_date(workspace_id, ending_datetime) do
    ending_datetime = ending_datetime |> DateTime.add(1)
    starting_datetime = DateTime.add(ending_datetime, -30, :day)

    # [ [date, [notes]], [date, [notes]] ]
    result =
      from(n in Note,
        where: n.inserted_at >= ^starting_datetime,
        where: n.inserted_at <= ^ending_datetime,
        where: n.workspace_id == ^workspace_id,
        order_by: [asc: n.id]
      )
      |> Repo.all()
      |> group_and_sort_notes()

    {result, starting_datetime}
  end

  def get_all_notes_for_workspace(workspace_id) do
    # Get all notes for a workspace, ordered by insertion date
    from(n in Note,
      where: n.workspace_id == ^workspace_id,
      order_by: [asc: n.id]
    )
    |> Repo.all()
    |> group_and_sort_notes()
  end

  def get_notes_grouped_and_ordered_till_date(workspace_id, datetime) do
    datetime = datetime |> DateTime.add(1)

    from(n in Note,
      where: n.inserted_at >= ^datetime,
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
    get_note_by_id(id)
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
    |> Enum.map(&Helpers.convert_timestamps_tz/1)
    |> Enum.group_by(fn %{inserted_at: inserted_at} ->
      inserted_at |> DateTime.to_date() |> Date.to_string()
    end)
    |> Enum.map(fn {date, notes} -> [date, notes] end)
    |> Enum.sort_by(fn [date, _] -> date end)
  end

  # Workspace stuff

  def get_all_workspaces() do
    from(w in Workspace, order_by: [asc: w.id])
    |> Repo.all()
    |> Enum.map(&Helpers.convert_timestamps_tz/1)
  end

  def get_public_workspaces() do
    from(w in Workspace, where: w.is_public == true, order_by: [asc: w.id])
    |> Repo.all()
    |> Enum.map(&Helpers.convert_timestamps_tz/1)
  end

  def get_workspace_by_id(id) do
    Repo.get!(Workspace, id)
  end

  # TODO: refactor
  def get_workspace(id) do
    Repo.get(Workspace, id)
  end

  def create_new_workspace(params) do
    %Workspace{} |> Workspace.changeset(params) |> Repo.insert()
  end

  def update_workspace(id, params) do
    get_workspace_by_id(id)
    |> Workspace.changeset(params)
    |> Repo.update()
  end

  def delete_workspace(id) do
    get_workspace_by_id(id) |> Repo.delete()
  end

  def update_note_workspace(note_id, workspace_id) do
    get_note_by_id(note_id)
    |> Note.changeset(%{workspace_id: workspace_id})
    |> Repo.update()
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, @pubsub_topic)
  end

  def broadcast!(message) do
    Phoenix.PubSub.broadcast!(@pubsub, @pubsub_topic, message)
  end
end
