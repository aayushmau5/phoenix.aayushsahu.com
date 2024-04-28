defmodule AccumulatorWeb.NotesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Note}

  @max_file_entries 20
  @max_file_size 5_000_000_00

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
     |> assign(form: form)
     |> assign(uploaded_files: [])
     |> assign(search: to_form(%{"search" => ""}))
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_file_entries,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_event("validate", %{"note" => note_params} = _params, socket) do
    note_changeset = %Note{} |> Note.changeset(note_params)

    form =
      note_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, form: form)}
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

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  def handle_event("save", %{"note" => note_params} = _params, socket) do
    storage_directory = if files_present?(socket), do: Accumulator.Pastes.create_storage_dir()

    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        %{client_name: file_name, client_type: file_type} = entry
        santized_filename = Zarex.sanitize(file_name)

        dest = Path.join([storage_directory, santized_filename])
        File.cp!(path, dest)

        {:ok,
         %{
           name: santized_filename,
           type: file_type,
           storage_path: dest,
           access_path:
             "/uploads/#{Path.join(Path.basename(storage_directory), santized_filename)}"
         }}
      end)

    note_changeset =
      %Note{}
      |> Note.changeset(note_params)
      |> Ecto.Changeset.put_embed(:files, uploaded_files)

    socket =
      case Notes.insert(note_changeset) do
        {:ok, _note} ->
          form = %Note{} |> Note.changeset() |> to_form()

          {notes, _} = Notes.get_notes_grouped_and_ordered_by_date(Date.utc_today())

          socket
          |> assign(form: form)
          |> stream(:notes, notes, reset: true)
          # Event to automatically scroll to bottom
          |> push_event("new-note-scroll", %{})

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  def handle_event("search-change", _params, socket) do
    # Do nothing with the search bar change rn
    {:noreply, socket}
  end

  def handle_event("search-submit", %{"search" => search} = _params, socket) do
    # TODO: implement search functionality
    IO.inspect(search, label: "Search")
    {:noreply, socket}
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"

  defp files_present?(socket) do
    case uploaded_entries(socket, :files) do
      {[], []} -> false
      _ -> true
    end
  end

  defp days_ago(date_string) do
    date = Date.from_iso8601!(date_string)
    today = Date.utc_today()

    case Date.diff(today, date) do
      0 -> "today"
      1 -> "yesterday"
      x -> "#{x} days ago"
    end
  end

  def todos() do
    ~S"""
    TODOs:
     - need to think about the way to show datewise data. How to query such that the results come in a sorted way grouped by date?
     - Using form or file uploads: drop/click + input + enter to save
     - File and text UI
     - better UI(with custom components and stuff)
     - Infinite scroll for loading previous notes
     - on page load, the notes list should should from bottom instead of up. How to achieve this?


     For today:
     - Work: try to finish up the UI - 3 hours
     - Personal: Notes project - 2 hours
     - DSP - 2 hours
    """
  end
end
