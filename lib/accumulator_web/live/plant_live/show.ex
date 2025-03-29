defmodule AccumulatorWeb.PlantLive.Show do
  use AccumulatorWeb, :live_view
  alias Accumulator.Plants

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    plant = Plants.get_plant!(id)

    {:noreply,
     socket
     |> assign(:page_title, plant.name)
     |> assign(:plant, plant)
     |> assign(:form, to_form(%{"watered_on" => plant.watered_on}))
     |> assign(edit_date: false)}
  end

  @impl true
  def handle_event("log-today-entry", _, socket) do
    # TODO;
    {:noreply, socket}
  end

  def handle_event("enable-date-edit", _, socket) do
    {:noreply, assign(socket, edit_date: true)}
  end

  def handle_event("cancel-date-edit", _, socket) do
    {:noreply, assign(socket, edit_date: false)}
  end

  def handle_event("validate", _, socket) do
    {:noreply, socket}
  end

  def handle_event("save", %{"watered_on" => watered_on}, socket) do
    # TODO: save it to db
    dbg(watered_on)
    {:noreply, assign(socket, edit_date: false)}
  end

  def handle_event("delete-plant", _, socket) do
    {:ok, _} = socket.assigns.plant |> Plants.delete_plant()
    {:noreply, socket |> push_navigate(to: "/plants")}
  end
end
