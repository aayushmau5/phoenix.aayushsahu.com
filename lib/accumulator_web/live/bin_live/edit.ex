defmodule AccumulatorWeb.BinLive.Edit do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Pastes, Pastes.Paste}
  alias AccumulatorWeb.Presence

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
      <.render_or_show_error :if={!@loading and !@editing} paste={@paste} title="Edit paste">
        <.edit_form paste={@paste} form={@form} submit_disabled={@submit_disabled} />
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

    {:noreply, assign(socket, form: paste_form, submit_disabled: !paste_changeset.valid?)}
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
        {:ok, paste} ->
          Phoenix.PubSub.broadcast(Accumulator.PubSub, "paste_updates:#{paste.id}", %{
            event: :paste_update
          })

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

  defp paste_form(paste) do
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
end
