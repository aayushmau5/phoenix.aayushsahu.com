defmodule AccumulatorWeb.BinLive.Create do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Pastes, Pastes.Paste}

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

      <h1 class="text-center text-xl font-bold">Create a paste</h1>
      <.simple_form for={@form} id="paste_form" phx-submit="add_paste" phx-change="validate_paste">
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

        <%!-- File uploads --%>
        <label class="block font-bold" for={@uploads.files.ref}>Files</label>
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

        <%= for err <- upload_errors(@uploads.files) do %>
          <p class="text-sm text-red-500"><%= error_to_string(err) %></p>
        <% end %>

        <.input
          field={@form[:time_duration]}
          type="number"
          id="paste_expire_duration"
          label="Expire Duration"
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
            disabled={@submit_disabled}
            phx-disable-with="Saving..."
          >
            Save
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    paste_form = %Paste{} |> Paste.changeset() |> to_form

    {:ok,
     socket
     |> assign(
       page_title: "Create | LiveBin",
       form: paste_form,
       submit_disabled: true
     )
     |> allow_upload(:files,
       accept: :any,
       max_entries: @max_file_entries,
       max_file_size: @max_file_size
     )}
  end

  @impl true
  def handle_event("validate_paste", %{"paste" => paste_params}, socket) do
    paste_changeset = %Paste{} |> Paste.changeset(paste_params)

    paste_form =
      paste_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, form: paste_form, submit_disabled: !paste_changeset.valid?)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :files, ref)}
  end

  @impl true
  def handle_event("add_paste", %{"paste" => paste_params}, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :files, fn %{path: path}, entry ->
        %{client_name: file_name, client_type: file_type} = entry
        file_ext = Path.extname(file_name)

        dest =
          Path.join([
            :code.priv_dir(:accumulator),
            "uploads",
            Path.basename(path) <> file_ext
          ])

        # TODO: check if we have to mv instead of cp
        File.cp!(path, dest)

        {:ok,
         %{
           name: file_name,
           storage_path: dest,
           type: file_type,
           access_path: "/uploads/#{Path.basename(dest)}"
         }}
      end)

    paste_changeset =
      %Paste{}
      |> Paste.changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        get_expiration_time(paste_params["time_duration"], paste_params["time_type"])
      )
      |> Ecto.Changeset.put_embed(:files, uploaded_files)

    socket =
      case Pastes.add_paste(paste_changeset) do
        :ok -> push_navigate(socket, to: ~p"/bin")
        {:error, changeset} -> assign(socket, form: to_form(changeset))
      end

    {:noreply, socket}
  end

  defp get_expiration_time(duration, type) do
    duration = String.to_integer(duration)

    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(DateTime.utc_now(), duration, type) |> DateTime.truncate(:second)
  end

  defp error_to_string(:too_large), do: "Too large"
  defp error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp error_to_string(:too_many_files), do: "You have selected too many files"
end
