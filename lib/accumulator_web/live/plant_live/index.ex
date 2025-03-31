defmodule AccumulatorWeb.PlantLive.Index do
  use AccumulatorWeb, :live_view

  alias Accumulator.Plants
  alias Accumulator.Plants.Plant

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :plants, Plants.list_plants())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "🌱 New Plant")
    |> assign(:plant, %Plant{})
  end

  defp apply_action(socket, :new_ai, _params) do
    socket
    |> assign(:page_title, "🌱 New Plant")
    |> assign(:plant, %Plant{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "🪴 Plants")
    |> assign(:plant, nil)
  end

  @impl true
  def handle_info({AccumulatorWeb.PlantLive.FormComponent, {:saved, plant}}, socket) do
    {:noreply, stream_insert(socket, :plants, plant)}
  end

  def handle_info({:ai_processing_result, component_id, result}, socket) do
    send_update(AccumulatorWeb.PlantLive.AIFormComponent,
      id: component_id,
      ai_result: result
    )

    {:noreply, socket}
  end
end
