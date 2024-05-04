defmodule AccumulatorWeb.NotesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Note}

  @impl true
  def mount(_params, _session, socket) do
    form =
      %Note{}
      |> Note.changeset()
      |> to_form()

    socket =
      if connected?(socket) do
        start_date = Date.utc_today()

        {notes, pagination_date} =
          Notes.get_notes_grouped_and_ordered_by_date(start_date)

        socket
        |> stream_configure(:notes, dom_id: &Enum.at(&1, 0))
        |> stream(:notes, notes)
        |> assign(pagination_date: pagination_date)
      else
        socket
        |> stream(:notes, [])
      end

    {:ok,
     socket
     |> assign(page_title: "Notes")
     # Note submission form
     |> assign(form: form)
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
    note_changeset = Note.changeset(%Note{}, note_params)

    socket =
      case Notes.insert(note_changeset) do
        {:ok, _note} ->
          {notes, _} = Notes.get_notes_grouped_and_ordered_by_date(Date.utc_today())

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

    {notes, pagination_date} = Notes.get_notes_grouped_and_ordered_by_date(start_date)

    socket =
      socket
      |> assign(pagination_date: pagination_date)
      |> stream(:notes, Enum.reverse(notes), at: 0)

    {:noreply, socket}
  end

  # Note update handlers

  def handle_event("edit", %{"id" => id} = _params, socket) do
    note_form = Notes.get_by_id(id) |> Note.changeset() |> to_form()
    socket = assign(socket, is_editing: true, form: note_form, editing_note_id: id)
    {:noreply, socket}
  end

  def handle_event("update-note", %{"note" => note_params} = _params, socket) do
    note_id = socket.assigns.editing_note_id

    socket =
      case Notes.update(note_id, note_params) do
        {:ok, _note} ->
          {notes, _} = Notes.get_notes_grouped_and_ordered_by_date(Date.utc_today())

          socket
          |> stream(:notes, notes, reset: true)
          |> assign(is_editing: true, form: empty_form())

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply, assign(socket, is_editing: false, form: empty_form(), editing_note_id: nil)}
  end

  def handle_event("delete", %{"id" => id} = _params, socket) do
    {:ok, _} = Notes.delete(id)
    notes = Notes.get_notes_grouped_and_ordered_till_date(socket.assigns.pagination_date)
    {:noreply, stream(socket, :notes, notes, reset: true)}
  end

  # Search handlers

  def handle_event("search-change", _params, socket) do
    # Do nothing with the search bar change rn
    {:noreply, socket}
  end

  def handle_event("search-submit", %{"search" => search} = _params, socket) do
    # TODO: implement search functionality
    IO.inspect(search, label: "Search")
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
end
