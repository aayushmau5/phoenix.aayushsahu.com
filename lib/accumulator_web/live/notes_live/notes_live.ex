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
     # Note submission form
     |> assign(form: form)
     |> assign(uploaded_files: [])
     |> assign(search: to_form(%{"search" => ""}))
     # Existing note editing state
     |> assign(is_editing: false)
     # Existing note
     |> assign(note: nil)
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_file_entries,
       max_file_size: @max_file_size
     ), layout: {AccumulatorWeb.Layouts, :note}}
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
          form = empty_form()

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
    note = Notes.get_by_id(id)
    note_form = note |> Note.changeset() |> to_form()
    socket = assign(socket, is_editing: true, form: note_form, note: note)
    {:noreply, socket}
  end

  def handle_event("cancel-edit", _params, socket) do
    {:noreply, assign(socket, is_editing: false, form: empty_form(), note: nil)}
  end

  def handle_event("update-note", %{"note" => note_params} = _params, socket) do
    storage_directory = if files_present?(socket), do: get_or_create_storage_dir(socket)

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

    # paste_changeset =
    #   socket.assigns.note
    #   |> Note.changeset(note_params)
    #   |> assign_files(socket.assigns.note.files, uploaded_files)

    # paste_changeset =
    #   if storage_directory != nil,
    #     do: Ecto.Changeset.put_change(paste_changeset, :storage_directory, storage_directory),
    #     else: paste_changeset

    # socket =
    #   case Pastes.update_existing_paste(paste_changeset) do
    #     {:ok, paste} ->
    #       Phoenix.PubSub.broadcast(Accumulator.PubSub, "paste_updates:#{paste.id}", %{
    #         event: :paste_update
    #       })

    #       cleanup_deleted_files(socket)
    #       push_navigate(socket, to: "/bin/#{paste.id}/show")

    #     {:error, changeset} ->
    #       assign(socket, form: to_form(changeset))
    #   end

    # {:noreply, socket}

    socket = assign(socket, is_editing: false, form: empty_form(), note: nil)
    {:noreply, socket}
    # Editing ability: deleting files, adding files, editing notes
  end

  def handle_event("delete", %{"id" => id} = _params, socket) do
    {:ok, _} = Notes.delete(id)
    notes = Notes.get_notes_grouped_and_ordered_till_date(socket.assigns.pagination_date)
    {:noreply, stream(socket, :notes, notes, reset: true)}
  end

  def handle_event("remove-file", %{"index" => index}, socket) do
    index = String.to_integer(index)

    note =
      Map.update(socket.assigns.note, :files, [], fn files ->
        List.update_at(files, index, &Map.put(&1, :deleted, true))
      end)

    {:noreply, assign(socket, note: note)}
  end

  @impl true
  def handle_event("undo-remove-file", %{"index" => index}, socket) do
    index = String.to_integer(index)

    note =
      Map.update(socket.assigns.note, :files, [], fn files ->
        List.update_at(files, index, &Map.delete(&1, :deleted))
      end)

    {:noreply, assign(socket, note: note)}
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

  defp empty_form() do
    %Note{} |> Note.changeset() |> to_form()
  end

  defp get_or_create_storage_dir(socket) do
    case Map.get(socket.assigns.note, :storage_directory) do
      nil -> Accumulator.Pastes.create_storage_dir()
      dir -> dir
    end
  end

  defp assign_files(changeset, prev_files, new_files) do
    prev_files =
      prev_files
      |> Enum.filter(&(Map.get(&1, :deleted) != true))
      |> Enum.map(fn file ->
        file_value = %{
          type: file.type,
          name: file.name,
          access_path: file.access_path,
          storage_path: file.storage_path
        }

        Accumulator.Pastes.File.changeset(%Accumulator.Pastes.File{}, file_value)
      end)

    Ecto.Changeset.put_embed(
      changeset,
      :files,
      new_files ++ prev_files
    )
  end
end
