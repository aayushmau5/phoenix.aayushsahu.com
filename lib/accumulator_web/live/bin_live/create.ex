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

      <h1 class="text-center text-xl font-bold">Create a paste</h1>

      <div>
        <.simple_form
          for={@paste_form}
          id="paste_form"
          phx-submit="add_paste"
          phx-change="validate_paste"
        >
          <.input field={@paste_form[:title]} type="text" id="paste_title" label="Title" required />
          <.input
            field={@paste_form[:content]}
            type="textarea"
            id="paste_content"
            label="Content"
            required
          />

          <.input
            field={@paste_form[:time_duration]}
            type="number"
            id="paste_expire_duration"
            label="Expire Duration"
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
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    paste_form = %Paste{} |> Paste.changeset() |> to_form

    {:ok,
     assign(socket, page_title: "Create | LiveBin", paste_form: paste_form, submit_disabled: true)}
  end

  @impl true
  def handle_event("validate_paste", params, socket) do
    %{"paste" => paste_params} = params

    paste_changeset = %Paste{} |> Paste.changeset(paste_params)

    paste_form =
      paste_changeset
      |> Map.put(:action, :validate)
      |> to_form

    {:noreply, assign(socket, paste_form: paste_form, submit_disabled: !paste_changeset.valid?)}
  end

  @impl true
  def handle_event("add_paste", params, socket) do
    %{"paste" => paste_params} = params
    expire_at = get_expiration_time(paste_params["time_duration"], paste_params["time_type"])

    paste_changeset =
      %Paste{}
      |> Paste.changeset(paste_params)
      |> Ecto.Changeset.put_change(:expire_at, expire_at)

    socket =
      case Pastes.add_paste(paste_changeset) do
        :ok -> push_navigate(socket, to: ~p"/bin")
        {:error, changeset} -> assign(socket, paste_form: to_form(changeset))
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
end
