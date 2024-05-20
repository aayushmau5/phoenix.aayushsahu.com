defmodule AccumulatorWeb.NotesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Note, Notes.Workspace, Helpers}

  # TODO: edit workspace has "public" slider

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:notes, dom_id: &Enum.at(&1, 0))
     |> stream(:notes, [])
     |> assign(
       page_title: "Notes",
       workspaces: Notes.get_all_workspaces(),
       selected_workspace: nil,
       # Note submission form
       form: create_empty_form(:note),
       workspace_form: nil,
       editing_note_id: nil,
       search: to_form(%{"search" => ""}),
       page_error: nil,
       # Existing note editing state
       is_editing: false
     ), layout: {AccumulatorWeb.Layouts, :note}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    workspace_id = Map.get(params, "id")

    socket = handle_workspace(workspace_id, socket)

    {:noreply, socket}
  end

  def handle_workspace(nil, socket) do
    default_workspace = get_default_workspace(socket.assigns.workspaces)

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(
        default_workspace.id,
        Helpers.get_utc_datetime_from_date()
      )

    socket
    |> stream(:notes, notes)
    |> assign(
      pagination_date: pagination_date,
      selected_workspace: default_workspace
    )
  end

  def handle_workspace(workspace_id, socket) do
    workspace =
      case Integer.parse(workspace_id) do
        {id, ""} -> Notes.get_workspace(id)
        _ -> nil
      end

    case workspace do
      nil ->
        assign(socket, page_error: :no_workspace)

      workspace ->
        {notes, pagination_date} =
          Notes.get_notes_grouped_and_ordered_by_date(
            workspace.id,
            Helpers.get_utc_datetime_from_date()
          )

        socket
        |> stream(:notes, notes, reset: true)
        |> assign(
          pagination_date: pagination_date,
          selected_workspace: workspace,
          page_error: nil
        )
        |> push_event("new-note-scroll", %{})
    end
  end

  # Note submission handlers

  @impl true
  def handle_event("validate", %{"note" => note_params} = _params, socket) do
    note_changeset = %Note{} |> Note.changeset(note_params)

    form =
      note_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, form: form)}
  end

  def handle_event("save", %{"note" => note_params} = _params, socket) do
    workspace_id = socket.assigns.selected_workspace.id
    note_params = Map.merge(note_params, %{"workspace_id" => workspace_id})
    note_changeset = Note.changeset(%Note{}, note_params)

    socket =
      case Notes.insert(note_changeset) do
        {:ok, note} ->
          {notes, _} =
            Notes.get_notes_grouped_and_ordered_by_date(
              workspace_id,
              Helpers.get_utc_datetime_from_date()
            )

          Notes.broadcast!(%{type: :new_note, workspace_id: note.workspace_id})

          socket
          |> assign(form: empty_form())
          |> stream(:notes, notes, reset: true)
          # Event to automatically scroll to bottom
          |> push_event("new-note-scroll", %{})

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("more-notes", _params, socket) do
    start_date = socket.assigns.pagination_date
    workspace_id = socket.assigns.selected_workspace.id

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(workspace_id, start_date)

    socket =
      socket
      |> assign(pagination_date: pagination_date)
      |> stream(:notes, Enum.reverse(notes), at: 0)

    {:noreply, socket}
  end

  # Note update handlers

  def handle_event("edit", %{"id" => id} = _params, socket) do
    note_form =
      Notes.get_note_by_id(id)
      |> Note.changeset()
      |> to_form()

    socket = assign(socket, is_editing: true, form: note_form, editing_note_id: id)
    {:noreply, socket}
  end

  def handle_event(
        "update-note",
        %{"note" => note_params, "workspace" => new_workspace_id} = _params,
        socket
      ) do
    note_id = socket.assigns.editing_note_id
    workspace_id = socket.assigns.selected_workspace.id

    socket =
      with {:ok, _} <- Notes.update_note(note_id, note_params),
           {:ok, _} <- update_note_workspace(note_id, new_workspace_id) do
        {notes, _} =
          Notes.get_notes_grouped_and_ordered_by_date(
            workspace_id,
            Helpers.get_utc_datetime_from_date()
          )

        Notes.broadcast!(%{type: :update_note, workspace_id: workspace_id})

        socket
        |> stream(:notes, notes, reset: true)
        |> assign(is_editing: false, form: empty_form(), editing_note_id: nil)
      else
        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply, assign(socket, is_editing: false, form: empty_form(), editing_note_id: nil)}
  end

  def handle_event("delete", %{"id" => id} = _params, socket) do
    {:ok, _} = Notes.delete_note(id)
    pagination_date = socket.assigns.pagination_date
    workspace_id = socket.assigns.selected_workspace.id

    Notes.broadcast!(%{type: :delete_note, workspace_id: workspace_id})

    notes = Notes.get_notes_grouped_and_ordered_till_date(workspace_id, pagination_date)
    {:noreply, stream(socket, :notes, notes, reset: true)}
  end

  # Search handlers

  def handle_event("search-change", _params, socket) do
    # Do nothing with the search bar change rn
    {:noreply, socket}
  end

  def handle_event("search-submit", %{"search" => search} = _params, socket) do
    search_term = String.trim(search)
    search_term_length = String.length(search_term)
    workspace_id = socket.assigns.selected_workspace.id

    socket =
      if search_term_length != 0 do
        notes = Notes.search_notes(workspace_id, search_term)

        socket |> stream(:notes, notes, reset: true) |> push_event("new-note-scroll", %{})
      else
        {notes, pagination_date} =
          Notes.get_notes_grouped_and_ordered_by_date(
            workspace_id,
            Helpers.get_utc_datetime_from_date()
          )

        socket
        |> stream(:notes, notes, reset: true)
        |> assign(pagination_date: pagination_date)
        |> push_event("new-note-scroll", %{})
      end

    {:noreply, socket}
  end

  # Workspace stuff

  def handle_event("new-workspace", _params, socket) do
    socket =
      socket
      |> assign(workspace_form: create_empty_form(:workspace))
      |> push_event("notes-workspace-modal", %{
        modal_id: "workspace-modal",
        attr: "data-show-modal"
      })

    {:noreply, socket}
  end

  def handle_event("edit-workspace", %{"id" => id} = _params, socket) do
    workspace_form = Notes.get_workspace_by_id(id) |> Workspace.changeset() |> to_form()

    socket =
      socket
      |> assign(
        workspace_edit_id: id,
        workspace_form: workspace_form
      )
      |> push_event("notes-workspace-modal", %{
        modal_id: "workspace-modal",
        attr: "data-show-modal"
      })

    {:noreply, socket}
  end

  def handle_event("workspace-form-change", %{"workspace" => workspace_params} = _params, socket) do
    workspace_form =
      %Workspace{}
      |> Workspace.changeset(workspace_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, workspace_form: workspace_form)}
  end

  def handle_event("workspace-form-submit", %{"workspace" => workspace_params} = _params, socket) do
    workspace_edit_id = Map.get(socket.assigns, :workspace_edit_id)

    socket =
      if workspace_edit_id != nil do
        case Notes.update_workspace(workspace_edit_id, workspace_params) do
          {:ok, _} ->
            workspaces = Notes.get_all_workspaces()

            Notes.broadcast!(%{type: :update_workspace, workspace_id: workspace_edit_id})

            socket
            |> assign(
              workspaces: workspaces,
              workspace_edit_id: nil
            )
            |> push_event("notes-workspace-modal", %{
              modal_id: "workspace-modal",
              attr: "data-hide-modal"
            })

          {:error, changeset} ->
            assign(socket, workspace_form: to_form(changeset))
        end
      else
        case Notes.create_new_workspace(workspace_params) do
          {:ok, workspace} ->
            workspaces = Notes.get_all_workspaces()

            Notes.broadcast!(%{type: :new_workspace, workspace_id: workspace.id})

            socket
            |> assign(workspaces: workspaces)
            |> push_event("notes-workspace-modal", %{
              modal_id: "workspace-modal",
              attr: "data-hide-modal"
            })

          {:error, changeset} ->
            assign(socket, workspace_form: to_form(changeset))
        end
      end

    {:noreply, socket}
  end

  def handle_event("delete-workspace", %{"id" => workspace_id} = _params, socket) do
    workspace_id = String.to_integer(workspace_id)

    {:ok, _} = Notes.delete_workspace(workspace_id)

    Notes.broadcast!(%{type: :delete_workspace, workspace_id: workspace_id})

    workspaces = Notes.get_all_workspaces()
    selected_workspace_id = socket.assigns.selected_workspace.id

    if selected_workspace_id == workspace_id,
      do: Process.send(self(), :change_to_default_workspace, [])

    {:noreply, assign(socket, workspaces: workspaces)}
  end

  @impl true
  def handle_info(:change_to_default_workspace, socket) do
    workspace = get_default_workspace(socket.assigns.workspaces)

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(
        workspace.id,
        Helpers.get_utc_datetime_from_date()
      )

    socket =
      socket
      |> stream(:notes, notes, reset: true)
      |> assign(
        selected_workspace: workspace,
        pagination_date: pagination_date
      )
      |> push_event("new-note-scroll", %{})
      |> push_patch(to: "/notes/#{workspace.id}")

    {:noreply, socket}
  end

  # Private functions

  defp empty_form() do
    %Note{} |> Note.changeset() |> to_form()
  end

  defp get_default_workspace(workspaces) do
    Enum.find(workspaces, fn workspace -> workspace.title === "default" end)
  end

  defp update_note_workspace(note_id, new_workspace_id) do
    change_workspace? = if String.length(new_workspace_id) == 0, do: false, else: true

    if change_workspace? do
      case Notes.update_note_workspace(note_id, new_workspace_id) do
        {:ok, note} -> {:ok, note}
        {:error, changeset} -> {:error, changeset}
      end
    else
      :ok
    end
  end

  defp create_empty_form(:note), do: %Note{} |> Note.changeset() |> to_form()
  defp create_empty_form(:workspace), do: %Workspace{} |> Workspace.changeset() |> to_form()
end
