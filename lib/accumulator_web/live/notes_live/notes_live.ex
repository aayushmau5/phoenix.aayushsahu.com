defmodule AccumulatorWeb.NotesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Note, Notes.Workspace}

  @impl true
  def mount(_params, _session, socket) do
    notes_form =
      %Note{}
      |> Note.changeset()
      |> to_form()

    socket =
      if connected?(socket) do
        workspaces = Notes.get_all_workspaces()
        default_workspace = get_default_workspace(workspaces)

        start_date = Date.utc_today()

        {notes, pagination_date} =
          Notes.get_notes_grouped_and_ordered_by_date(default_workspace.id, start_date)

        socket
        |> stream_configure(:notes, dom_id: &Enum.at(&1, 0))
        |> stream(:notes, notes)
        |> assign(:workspaces, workspaces)
        |> assign(pagination_date: pagination_date)
        |> assign(selected_workspace: default_workspace)
      else
        socket
        |> stream(:notes, [])
        |> assign(:workspaces, [])
        |> assign(selected_workspace: nil)
      end

    {:ok,
     socket
     |> assign(page_title: "Notes")
     # Note submission form
     |> assign(form: notes_form)
     |> assign(workspace_form: nil)
     |> assign(editing_note_id: nil)
     |> assign(uploaded_files: [])
     |> assign(search: to_form(%{"search" => ""}))
     # Existing note editing state
     |> assign(is_editing: false), layout: {AccumulatorWeb.Layouts, :note}}
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
        {:ok, _note} ->
          {notes, _} = Notes.get_notes_grouped_and_ordered_by_date(workspace_id, Date.utc_today())

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
           :ok <- update_note_workspace(note_id, new_workspace_id) do
        {notes, _} =
          Notes.get_notes_grouped_and_ordered_by_date(workspace_id, Date.utc_today())

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
          Notes.get_notes_grouped_and_ordered_by_date(workspace_id, Date.utc_today())

        socket
        |> stream(:notes, notes, reset: true)
        |> assign(pagination_date: pagination_date)
        |> push_event("new-note-scroll", %{})
      end

    {:noreply, socket}
  end

  # Workspace stuff

  def handle_event("change-workspace", %{"id" => id} = _params, socket) do
    workspace = Notes.get_workspace_by_id(id)

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(workspace.id, Date.utc_today())

    socket =
      socket
      |> assign(selected_workspace: workspace)
      |> assign(pagination_date: pagination_date)
      |> stream(:notes, notes, reset: true)
      |> push_event("new-note-scroll", %{})

    {:noreply, socket}
  end

  def handle_event("new-workspace", _params, socket) do
    workspace_form = %Workspace{} |> Workspace.changeset() |> to_form()

    socket =
      socket
      |> assign(workspace_form: workspace_form)
      |> push_event("notes-workspace-modal", %{
        modal_id: "workspace-modal",
        attr: "data-show-modal"
      })

    {:noreply, socket}
  end

  def handle_event("edit-workspace", %{"id" => id} = _params, socket) do
    workspace = Notes.get_workspace_by_id(id)

    socket =
      if workspace != nil do
        workspace_form = workspace |> Workspace.changeset() |> to_form()

        socket
        |> assign(workspace_edit_id: id)
        |> assign(workspace_form: workspace_form)
        |> push_event("notes-workspace-modal", %{
          modal_id: "workspace-modal",
          attr: "data-show-modal"
        })
      else
        socket
      end

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
        case Notes.rename_workspace(workspace_edit_id, workspace_params) do
          {:ok, _} ->
            workspaces = Notes.get_all_workspaces()

            socket
            |> assign(workspaces: workspaces)
            |> assign(workspace_edit_id: nil)
            |> push_event("notes-workspace-modal", %{
              modal_id: "workspace-modal",
              attr: "data-hide-modal"
            })

          {:error, changeset} ->
            assign(socket, workspace_form: to_form(changeset))
        end
      else
        case Notes.create_new_workspace(workspace_params) do
          {:ok, _} ->
            workspaces = Notes.get_all_workspaces()

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

    socket =
      case Notes.delete_workspace(workspace_id) do
        nil ->
          socket

        _ ->
          workspaces = Notes.get_all_workspaces()
          selected_workspace_id = socket.assigns.selected_workspace.id

          if selected_workspace_id == workspace_id,
            do: Process.send(self(), :change_to_default_workspace, [])

          assign(socket, workspaces: workspaces)
      end

    {:noreply, socket}
  end

  @impl true
  def handle_info(:change_to_default_workspace, socket) do
    workspace = get_default_workspace(socket.assigns.workspaces)

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(workspace.id, Date.utc_today())

    socket =
      socket
      |> assign(selected_workspace: workspace)
      |> assign(pagination_date: pagination_date)
      |> stream(:notes, notes, reset: true)
      |> push_event("new-note-scroll", %{})

    {:noreply, socket}
  end

  # Private functions

  defp days_ago(date_string) do
    date = Date.from_iso8601!(date_string)
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 -> "today"
      1 -> "yesterday"
      x -> "#{x} days ago"
    end
  end

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
        {:ok, _} -> :ok
        {:error, changeset} -> {:error, changeset}
      end
    else
      :ok
    end
  end

  # defp assign_form(socket, %Ecto.Changeset{} = changeset, :note) do
  #   assign(socket, :form, to_form(changeset))
  # end

  # defp assign_form(socket, %Ecto.Changeset{} = changeset, :workspace) do
  #   assign(socket, :workspace_form, to_form(changeset))
  # end
end
