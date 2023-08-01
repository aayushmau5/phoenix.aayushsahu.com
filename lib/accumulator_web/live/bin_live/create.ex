defmodule AccumulatorWeb.BinLive.Create do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Pastes, Pastes.Paste}

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-2 text-xl font-bold">LiveBin</div>

      <.back navigate={~p"/bin"}>
        Back
      </.back>

      <%!-- <.form for={@form} phx-change="file-input">
        <label class="block font-bold" for={@uploads.files.ref}>Files</label>
        <.live_file_input style="margin-top:10px;" upload={@uploads.files} />
        <%= for entry <- @uploads.files.entries do %>
          <div>
            Name: <%= entry.client_name %>
            <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
            <button
              type="button"
              phx-click="cancel-upload"
              phx-value-ref={entry.ref}
              aria-label="cancel"
            >
              &times;
            </button>
            <%= for err <- upload_errors(@uploads.files, entry) do %>
              <p class="alert alert-danger"><%= error_to_string(err) %></p>
            <% end %>
          </div>
        <% end %>
      </.form> --%>

      <div>
        Hello <%= length(@uploads.files.entries) %>
      </div>

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
        <div :for={entry <- @uploads.files.entries}>
          Name: <%= entry.client_name %>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
          <button
            type="button"
            phx-click="cancel-upload"
            phx-value-ref={entry.ref}
            aria-label="cancel"
          >
            &times;
          </button>
          <%= for err <- upload_errors(@uploads.files, entry) do %>
            <p class="alert alert-danger"><%= error_to_string(err) %></p>
          <% end %>
        </div>

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
       submit_disabled: true,
       uploaded_files: []
     )
     |> allow_upload(:files, accept: :any, max_entries: 20, max_file_size: 5_000_000)}
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
  def handle_event("add_paste", %{"paste" => paste_params}, socket) do
    expire_at = get_expiration_time(paste_params["time_duration"], paste_params["time_type"])

    paste_changeset =
      %Paste{}
      |> Paste.changeset(paste_params)
      |> Ecto.Changeset.put_change(:expire_at, expire_at)

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
