defmodule AccumulatorWeb.BinLive.Edit do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Pastes, Pastes.Paste}
  alias AccumulatorWeb.Presence

  @max_file_entries 20
  @max_file_size 5_000_000_00

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-2 text-xl font-bold">LiveBin</div>

      <.back navigate={~p"/bin"}>
        Back
      </.back>

      <div :if={@loading}>Loading...</div>
      <div :if={@editing} class="text-center font-bold mt-2">
        Someone else is editing the form. Try again after some time.
      </div>
      <.render_or_show_error :if={!@loading and !@editing} paste={@paste}>
        <h1 class="text-center text-xl font-bold">Edit paste</h1>
        <.simple_form
          for={@form}
          id="paste_form"
          phx-submit="update_paste"
          phx-change="validate_paste"
        >
          <.input field={@form[:title]} type="text" id="paste_title" label="Title" required />
          <.input
            field={@form[:content]}
            type="textarea"
            id="paste_content"
            label="Content"
            data-attrs="style"
            phx-hook="MaintainAttrs"
            required
          />

          <div :if={@paste.files != []}>
            <p class="block font-semibold text-sm">Files</p>
            <div
              :for={{file, index} <- Enum.with_index(@paste.files)}
              class="mt-2 bg-white bg-opacity-5 p-2 rounded-md"
            >
              <a
                href={file.access_path}
                class={"#{if Map.get(file, :deleted) == true, do: "opacity-30", else: ""}"}
              >
                <%= file.name %>
              </a>
              <div class="text-sm opacity-40"><%= file.type %></div>
              <%= if Map.get(file, :deleted) == true do %>
                <div class="flex items-center justify-between gap-2">
                  <p class="text-sm opacity-50">Deleted</p>
                  <button type="button" phx-click="undo-remove-file" phx-value-index={index}>
                    Undo
                  </button>
                </div>
              <% else %>
                <button
                  type="button"
                  phx-click="remove-file"
                  phx-value-index={index}
                  class="text-sm text-red-400"
                >
                  Remove
                </button>
              <% end %>
            </div>
          </div>

          <%!-- File uploads --%>
          <label class="block font-semibold text-sm" for={@uploads.files.ref}>Add Files</label>
          <.live_file_input style="margin-top:10px;" upload={@uploads.files} />
          <div :for={entry <- @uploads.files.entries} class="flex justify-between">
            <div>
              <div><%= entry.client_name %></div>
              <div class="text-sm opacity-30"><%= entry.client_type %></div>
              <button
                type="button"
                phx-click="cancel-upload"
                phx-value-ref={entry.ref}
                class="block text-sm"
              >
                Cancel
              </button>
              <%= for err <- upload_errors(@uploads.files, entry) do %>
                <p class="text-sm text-red-500"><%= error_to_string(err) %></p>
              <% end %>
            </div>

            <div>
              <progress class="rounded-md" value={entry.progress} max="100">
                <%= entry.progress %>%
              </progress>
            </div>
          </div>

          <div :if={@file_limit_exceeded?} class="text-red-500">
            File limit exceeded
          </div>

          <%= for err <- upload_errors(@uploads.files) do %>
            <p class="text-sm text-red-500"><%= error_to_string(err) %></p>
          <% end %>

          <div>Expires at: <.local_time id="paste-expire-time" date={@paste.expire_at} /></div>

          <.input
            field={@form[:time_duration]}
            type="number"
            id="paste_expire_duration"
            label="Extend Expire Duration"
            required
          />
          <.input
            field={@form[:time_type]}
            type="select"
            id="paste_expire_type"
            label="Expire Type"
            options={["minute", "hour", "day"]}
            required
          />
          <:actions>
            <.button
              class="disabled:bg-red-400"
              disabled={@submit_disabled || @file_limit_exceeded?}
              phx-disable-with="Saving..."
            >
              Save
            </.button>
          </:actions>
        </.simple_form>
      </.render_or_show_error>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    loading = if connected?(socket), do: false, else: true
    paste = show_paste(socket, params)
    editing = editing?(socket, paste)

    {:ok,
     assign(socket,
       page_title: "Edit | LiveBin",
       loading: loading,
       editing: editing,
       paste: paste,
       form: paste_form(paste),
       file_limit_exceeded?: false,
       submit_disabled: false
     )
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_file_entries,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_event("remove-file", %{"index" => index}, socket) do
    index = String.to_integer(index)

    paste =
      Map.update(socket.assigns.paste, :files, [], fn files ->
        List.update_at(files, index, &Map.put(&1, :deleted, true))
      end)

    socket = assign(socket, paste: paste)
    socket = assign(socket, file_limit_exceeded?: file_limit_exceeded?(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_event("undo-remove-file", %{"index" => index}, socket) do
    index = String.to_integer(index)

    paste =
      Map.update(socket.assigns.paste, :files, [], fn files ->
        List.update_at(files, index, &Map.delete(&1, :deleted))
      end)

    socket = assign(socket, paste: paste)
    socket = assign(socket, file_limit_exceeded?: file_limit_exceeded?(socket))

    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    socket = cancel_upload(socket, :files, ref)
    {:noreply, assign(socket, file_limit_exceeded?: file_limit_exceeded?(socket))}
  end

  @impl true
  def handle_event("validate_paste", %{"paste" => paste_params}, socket) do
    paste_changeset = %Paste{} |> Paste.update_changeset(paste_params)

    paste_form =
      paste_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply,
     assign(socket,
       form: paste_form,
       submit_disabled: !paste_changeset.valid?,
       file_limit_exceeded?: file_limit_exceeded?(socket)
     )}
  end

  def handle_event("update_paste", %{"paste" => paste_params}, socket) do
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

    paste_changeset =
      socket.assigns.paste
      |> Paste.update_changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        extend_expiration_time(
          socket.assigns.paste.expire_at,
          paste_params["time_duration"],
          paste_params["time_type"]
        )
      )
      |> assign_files(socket.assigns.paste.files, uploaded_files)

    paste_changeset =
      if storage_directory != nil,
        do: Ecto.Changeset.put_change(paste_changeset, :storage_directory, storage_directory),
        else: paste_changeset

    socket =
      case Pastes.update_existing_paste(paste_changeset) do
        {:ok, paste} ->
          Phoenix.PubSub.broadcast(Accumulator.PubSub, "paste_updates:#{paste.id}", %{
            event: :paste_update
          })

          cleanup_deleted_files(socket)
          push_navigate(socket, to: "/bin/#{paste.id}/show")

        {:error, changeset} ->
          assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  defp extend_expiration_time(expiratio_time, duration, type) do
    duration = String.to_integer(duration)

    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(expiratio_time, duration, type) |> DateTime.truncate(:second)
  end

  defp editing?(socket, paste) do
    if connected?(socket) && paste not in [nil, :error] do
      topic = "paste_edit:#{paste.id}"
      count = Presence.list(topic) |> map_size()

      if count == 0 do
        {:ok, _} = Presence.track(self(), topic, socket.id, %{})
        false
      else
        true
      end
    else
      false
    end
  end

  defp paste_form(:error), do: nil
  defp paste_form(nil), do: nil

  defp paste_form(paste) do
    paste
    |> Map.merge(%{time_duration: 0, time_type: "minute"})
    |> Paste.update_changeset()
    |> to_form
  end

  defp show_paste(socket, params) do
    paste_id = Map.get(params, "id")

    if connected?(socket) do
      case Integer.parse(paste_id) do
        {id, ""} -> Pastes.get_paste(id)
        {_, _} -> :error
        :error -> :error
      end
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

  defp file_limit_exceeded?(socket) do
    non_deleted_files = Enum.filter(socket.assigns.paste.files, &(Map.get(&1, :deleted) != true))

    current_files_present =
      length(non_deleted_files) + length(socket.assigns.uploads.files.entries)

    current_files_present > @max_file_entries
  end

  defp get_or_create_storage_dir(socket) do
    case Map.get(socket.assigns.paste, :storage_directory) do
      nil -> Pastes.create_storage_dir()
      dir -> dir
    end
  end

  defp cleanup_deleted_files(socket) do
    Enum.filter(socket.assigns.paste.files, &(Map.get(&1, :deleted) == true))
    |> Pastes.cleanup_files()
  end

  defp files_present?(socket) do
    case uploaded_entries(socket, :files) do
      {[], []} -> false
      _ -> true
    end
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
