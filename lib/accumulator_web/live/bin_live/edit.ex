defmodule AccumulatorWeb.BinLive.Edit do
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

      <%= if @loading do %>
        <div>Loading...</div>
      <% else %>
        <%= case @paste do %>
          <% nil -> %>
            <div class="text-xl text-center font-bold">
              No paste found! It either expired or doesn't exist.
            </div>
          <% :error -> %>
            <div class="text-xl text-center font-bold">Invalid paste id provided.</div>
          <% paste -> %>
            <div>
              <h1 class="text-center text-xl font-bold">Edit paste</h1>

              <.simple_form
                for={@paste_form}
                id="paste_form"
                phx-submit="update_paste"
                phx-change="validate_paste"
              >
                <.input
                  field={@paste_form[:title]}
                  type="text"
                  id="paste_title"
                  label="Title"
                  required
                />
                <.input
                  field={@paste_form[:content]}
                  type="textarea"
                  id="paste_content"
                  label="Content"
                  required
                />

                <div>Expires at: <.local_time id="paste-expire-time" date={paste.expire_at} /></div>

                <.input
                  field={@paste_form[:time_duration]}
                  type="number"
                  id="paste_expire_duration"
                  label="Extend Expire Duration"
                  required
                />
                <.input
                  field={@paste_form[:time_type]}
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
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    loading = if connected?(socket), do: false, else: true
    paste = show_paste(socket, params)

    paste_form =
      case paste do
        :error ->
          nil

        nil ->
          nil

        paste ->
          paste
          |> Map.merge(%{time_duration: 0, time_type: "minute"})
          |> Paste.update_changeset()
          |> to_form
      end

    {:ok,
     assign(socket,
       page_title: "Edit | LiveBin",
       loading: loading,
       paste: paste,
       paste_form: paste_form,
       submit_disabled: false
     )}
  end

  @impl true
  def handle_event("validate_paste", %{"paste" => paste_params}, socket) do
    paste_changeset = %Paste{} |> Paste.update_changeset(paste_params)

    paste_form =
      paste_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, paste_form: paste_form, submit_disabled: !paste_changeset.valid?)}
  end

  @impl true
  def handle_event("update_paste", %{"paste" => paste_params}, socket) do
    expire_at =
      extend_expiration_time(
        socket.assigns.paste.expire_at,
        paste_params["time_duration"],
        paste_params["time_type"]
      )

    paste_changeset =
      socket.assigns.paste
      |> Paste.update_changeset(paste_params)
      |> Ecto.Changeset.put_change(:expire_at, expire_at)

    socket =
      case Pastes.update_existing_paste(paste_changeset) do
        {:ok, paste} -> push_navigate(socket, to: "/bin/#{paste.id}/show")
        {:error, changeset} -> assign(socket, paste_form: to_form(changeset))
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

  def show_paste(socket, params) do
    paste_id = Map.get(params, "id")

    if connected?(socket) do
      case Integer.parse(paste_id) do
        {id, ""} -> Pastes.get_paste(id)
        {_, _} -> :error
        :error -> :error
      end
    end
  end
end
