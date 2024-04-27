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
        notes = Notes.get_by_ascending_order()
        stream(socket, :notes, notes)
      else
        stream(socket, :notes, [])
      end

    {:ok,
     socket
     |> assign(page_title: "Notes")
     |> assign(form: form)
     |> assign(uploaded_files: [])
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_file_entries,
       max_file_size: @max_file_size
     )
     |> assign(search: to_form(%{"search" => ""}))}
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

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
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
        {:ok, note} ->
          form = %Note{} |> Note.changeset() |> to_form()

          socket
          |> assign(form: form)
          |> stream_insert(:notes, note)

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  @impl true
  def handle_event("search-change", _params, socket) do
    # Do nothing with the search bar change rn
    {:noreply, socket}
  end

  @impl true
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

  def todos() do
    ~S"""
    TODOs:
     - need to think about the way to show datewise data. How to query such that the results come in a sorted way grouped by date?
     - Using form or file uploads: drop/click + input + enter to save
     - File and text UI
     - Pagination and handling lots of data in the DOM(virtual lists?)


     For today:
     - Work: try to finish up the UI - 3 hours
     - Personal: Notes project - 2 hours
     - DSP - 2 hours
    """
  end
end
