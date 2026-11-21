defmodule AccumulatorWeb.PhotosLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Photos

  @max_entries 10
  @max_file_size 30_000_000

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="photos-page"
      phx-hook="PhotosPage"
      class={["md:pb-0", if(@selected, do: "pb-[60vh]", else: "pb-24")]}
    >
      <div
        id="photos-drop-overlay"
        phx-update="ignore"
        class="pointer-events-none fixed inset-0 z-40 hidden items-center justify-center bg-black/80 text-lg"
      >
        Drop to upload
      </div>

      <form id="photo-upload-form" phx-change="validate_upload">
        <.live_file_input upload={@uploads.photos} class="sr-only" />
      </form>

      <div class="mb-4 flex items-center justify-between">
        <div class="flex items-baseline gap-2">
          <span class="text-xl font-bold">Photos</span>
          <span id="photos-count" class="text-sm text-zinc-500">{@count}</span>
        </div>
        <div class="hidden items-center gap-4 md:flex">
          <span class="text-xs text-zinc-500">Drop anywhere or paste</span>
          <label
            for={@uploads.photos.ref}
            class="flex cursor-pointer items-center gap-1 bg-[#0f4e28] px-3 py-2 text-sm font-semibold transition hover:bg-[#13643a]"
          >
            <Heroicons.plus class="h-4" /> Add photos
          </label>
        </div>
      </div>

      <p :for={err <- upload_errors(@uploads.photos)} class="mb-3 text-sm text-red-400">
        {error_to_string(err)}
      </p>

      <div class={[
        "md:grid md:items-start md:gap-4",
        @selected && "md:grid-cols-[minmax(0,1fr)_320px]"
      ]}>
        <div class="grid grid-cols-2 gap-1.5 md:grid-cols-4">
          <div id="photo-uploads" class="contents">
            <div
              :for={entry <- @uploads.photos.entries}
              id={"upload-#{entry.ref}"}
              class="flex aspect-square flex-col justify-end border border-dashed border-zinc-600 bg-[#161618] p-2"
            >
              <span class="truncate text-xs text-zinc-400">{entry.client_name}</span>
              <%= if upload_errors(@uploads.photos, entry) == [] do %>
                <div class="mt-1 h-1 bg-zinc-700">
                  <div class="h-1 bg-green-500 transition-all" style={"width: #{entry.progress}%"}>
                  </div>
                </div>
              <% else %>
                <p
                  :for={err <- upload_errors(@uploads.photos, entry)}
                  class="mt-1 text-xs text-red-400"
                >
                  {error_to_string(err)}
                </p>
                <button
                  type="button"
                  phx-click="cancel_upload"
                  phx-value-ref={entry.ref}
                  class="mt-1 self-start text-xs underline"
                >
                  Dismiss
                </button>
              <% end %>
            </div>
            <div
              :for={{ref, name} <- @processing}
              id={"processing-#{ref}"}
              class="flex aspect-square animate-pulse flex-col justify-end bg-[#1d1d1f] p-2"
            >
              <span class="truncate text-xs text-zinc-400">{name}</span>
              <span class="text-xs text-zinc-500">Processing...</span>
            </div>
          </div>

          <div id="photos" phx-update="stream" class="contents">
            <div
              id="photos-empty"
              class="col-span-full hidden py-20 text-center text-sm text-zinc-500 only:block"
            >
              Your photos will show up here. Drop some in or use Add photos.
            </div>
            <button
              :for={{id, photo} <- @streams.photos}
              id={id}
              type="button"
              phx-click="select"
              phx-value-id={photo.id}
              class={[
                "group relative aspect-square overflow-hidden bg-[#1d1d1f] focus:outline-none",
                selected?(@selected, photo) && "outline outline-2 outline-offset-2 outline-green-400"
              ]}
            >
              <img
                src={thumb_url(photo)}
                alt={photo.caption || ""}
                loading="lazy"
                class="h-full w-full object-cover transition duration-200 group-hover:scale-[1.03] group-hover:opacity-90"
              />
              <span
                :if={is_nil(photo.caption)}
                class="absolute right-1 top-1 bg-black/70 px-1.5 py-0.5 text-[10px] text-zinc-300"
              >
                No caption
              </span>
            </button>
          </div>
        </div>

        <div
          :if={@selected}
          id="photo-panel"
          class="fixed inset-x-0 bottom-0 z-30 max-h-[85dvh] overflow-y-auto border-t border-zinc-700 bg-[#161618] px-3 pb-4 pt-2 md:sticky md:top-4 md:max-h-none md:border md:p-3"
        >
          <button
            type="button"
            phx-click="close_panel"
            aria-label="Close"
            class="mx-auto mb-3 block h-1.5 w-12 rounded-full bg-zinc-600 md:hidden"
          >
          </button>

          <img
            src={full_url(@selected)}
            width={@selected.width}
            height={@selected.height}
            alt={@selected.caption || ""}
            class="mb-3 hidden h-auto max-h-[45vh] w-full bg-black object-contain md:block"
          />

          <div class="flex items-center gap-2">
            <button
              type="button"
              phx-click="select_adjacent"
              phx-value-dir="prev"
              aria-label="Previous photo"
              class="flex h-9 w-9 shrink-0 items-center justify-center border border-zinc-700 hover:bg-[#373739]"
            >
              <Heroicons.chevron_left class="h-4" />
            </button>
            <img src={thumb_url(@selected)} alt="" class="h-12 w-12 shrink-0 object-cover md:hidden" />
            <div class="flex-1 text-xs leading-5">
              <div class="text-zinc-400">{format_date(@selected.taken_at)}</div>
              <div id="photo-save-state" class={save_state_class(@save_state)}>
                {save_state_text(@save_state)}
              </div>
            </div>
            <button
              type="button"
              phx-click="select_adjacent"
              phx-value-dir="next"
              aria-label="Next photo"
              class="flex h-9 w-9 shrink-0 items-center justify-center border border-zinc-700 hover:bg-[#373739]"
            >
              <Heroicons.chevron_right class="h-4" />
            </button>
          </div>

          <.form
            for={@form}
            id={"photo-details-form-#{@selected.id}"}
            phx-change="save_details"
            phx-submit="save_details"
            class="mt-1"
          >
            <input type="hidden" name="photo_id" value={@selected.id} />
            <.input
              field={@form[:caption]}
              type="textarea"
              label="Caption"
              rows="2"
              phx-debounce="600"
            />
            <.input field={@form[:place]} type="text" label="Place" phx-debounce="600" />
          </.form>

          <div class="mt-4 flex items-center justify-between border-t border-zinc-800 pt-3 text-xs">
            <span class="hidden text-zinc-500 md:inline">Arrows to move, Esc to close</span>
            <button
              type="button"
              phx-click="delete"
              data-confirm="Delete this photo? This removes its files too."
              class="flex items-center gap-1 text-red-400 hover:text-red-300"
            >
              <Heroicons.trash class="h-4" /> Delete
            </button>
          </div>
        </div>
      </div>

      <label
        :if={!@selected}
        for={@uploads.photos.ref}
        class="fixed inset-x-4 bottom-4 z-20 flex h-12 cursor-pointer items-center justify-center gap-2 bg-[#0f4e28] font-semibold active:bg-[#13643a] md:hidden"
      >
        <Heroicons.plus class="h-5" /> Add photos
      </label>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    photos = Photos.list_photos()

    {:ok,
     socket
     |> assign(
       page_title: "Photos",
       count: length(photos),
       photo_ids: Enum.map(photos, & &1.id),
       selected: nil,
       form: nil,
       save_state: :idle,
       processing: %{}
     )
     |> stream(:photos, photos)
     |> allow_upload(:photos,
       accept: ~w(.jpg .jpeg .png .webp),
       max_entries: @max_entries,
       max_file_size: @max_file_size,
       auto_upload: true,
       progress: &handle_progress/3
     )}
  end

  @impl true
  def handle_event("validate_upload", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :photos, ref)}
  end

  def handle_event("select", %{"id" => id}, socket) do
    {:noreply, select_photo(socket, Photos.get_photo!(id))}
  end

  def handle_event("select_adjacent", %{"dir" => dir}, socket) do
    case adjacent_id(socket.assigns, dir) do
      nil -> {:noreply, socket}
      id -> {:noreply, select_photo(socket, Photos.get_photo!(id))}
    end
  end

  def handle_event("close_panel", _params, socket) do
    {:noreply, close_panel(socket)}
  end

  def handle_event("save_details", _params, %{assigns: %{selected: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("save_details", %{"photo_id" => id, "photo" => params}, socket) do
    if to_string(socket.assigns.selected.id) == id do
      save_selected_details(socket, params)
    else
      save_other_details(socket, Photos.get_photo!(id), params)
    end
  end

  def handle_event("delete", _params, %{assigns: %{selected: nil}} = socket) do
    {:noreply, socket}
  end

  def handle_event("delete", _params, socket) do
    photo = socket.assigns.selected
    {:ok, _} = Photos.delete_photo(photo)

    {:noreply,
     socket
     |> assign(selected: nil, form: nil, save_state: :idle)
     |> update(:photo_ids, &List.delete(&1, photo.id))
     |> update(:count, &(&1 - 1))
     |> stream_delete(:photos, photo)}
  end

  @impl true
  def handle_async({:process, ref}, result, socket) do
    {name, processing} = Map.pop(socket.assigns.processing, ref)
    socket = assign(socket, processing: processing)

    case result do
      {:ok, {:ok, photo}} ->
        {:noreply,
         socket
         |> update(:photo_ids, &[photo.id | &1])
         |> update(:count, &(&1 + 1))
         |> stream_insert(:photos, photo, at: 0)}

      _ ->
        {:noreply, put_flash(socket, :error, "Couldn't process #{name}. Try another file.")}
    end
  end

  defp handle_progress(:photos, %{done?: false}, socket), do: {:noreply, socket}

  defp handle_progress(:photos, entry, socket) do
    tmp_path =
      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        dest = Path.join(System.tmp_dir!(), "photo-upload-#{entry.uuid}")
        File.cp!(path, dest)
        {:ok, dest}
      end)

    {:noreply,
     socket
     |> update(:processing, &Map.put(&1, entry.ref, entry.client_name))
     |> start_async({:process, entry.ref}, fn -> process_upload(tmp_path) end)}
  end

  defp process_upload(tmp_path) do
    Photos.create_photo(tmp_path)
  after
    File.rm(tmp_path)
  end

  defp select_photo(socket, photo) do
    socket
    |> reinsert_selected()
    |> assign(
      selected: photo,
      form: details_form(photo, Photos.change_photo_details(photo)),
      save_state: :idle
    )
    |> stream_insert(:photos, photo)
  end

  defp save_selected_details(socket, params) do
    photo = socket.assigns.selected

    case Photos.update_photo_details(photo, params) do
      {:ok, photo} ->
        {:noreply,
         socket
         |> assign(selected: photo, save_state: :saved)
         |> stream_insert(:photos, photo)}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           form: details_form(photo, Map.put(changeset, :action, :validate)),
           save_state: :error
         )}
    end
  end

  defp save_other_details(socket, photo, params) do
    case Photos.update_photo_details(photo, params) do
      {:ok, photo} -> {:noreply, stream_insert(socket, :photos, photo)}
      {:error, _changeset} -> {:noreply, socket}
    end
  end

  defp details_form(photo, changeset), do: to_form(changeset, id: "photo-#{photo.id}")

  defp close_panel(socket) do
    socket
    |> reinsert_selected()
    |> assign(selected: nil, form: nil, save_state: :idle)
  end

  defp reinsert_selected(%{assigns: %{selected: nil}} = socket), do: socket

  defp reinsert_selected(socket) do
    selected = socket.assigns.selected
    socket |> assign(selected: nil) |> stream_insert(:photos, selected)
  end

  defp adjacent_id(%{selected: nil}, _dir), do: nil

  defp adjacent_id(%{selected: selected, photo_ids: ids}, dir) do
    index = Enum.find_index(ids, &(&1 == selected.id))
    offset = if dir == "next", do: 1, else: -1
    target = index && index + offset

    if target && target >= 0, do: Enum.at(ids, target)
  end

  defp selected?(nil, _photo), do: false
  defp selected?(selected, photo), do: selected.id == photo.id

  defp thumb_url(photo), do: "/uploads/photos/#{photo.id}/thumb.webp"
  defp full_url(photo), do: "/uploads/photos/#{photo.id}/full.webp"

  defp format_date(datetime), do: Calendar.strftime(datetime, "%b %d, %Y")

  defp save_state_text(:saved), do: "Saved"
  defp save_state_text(:error), do: "Not saved, check the fields"
  defp save_state_text(:idle), do: ""

  defp save_state_class(:saved), do: "text-green-400"
  defp save_state_class(:error), do: "text-red-400"
  defp save_state_class(:idle), do: "text-zinc-500"

  defp error_to_string(:too_large), do: "Too large (max 30 MB)"
  defp error_to_string(:too_many_files), do: "Too many at once (max #{@max_entries})"
  defp error_to_string(:not_accepted), do: "Only JPEG, PNG or WebP"
  defp error_to_string(_), do: "Upload failed"
end
