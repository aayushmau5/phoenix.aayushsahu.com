defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view
  import AccumulatorWeb.DashboardComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(page_title: "Accumulator Dashboard")}
  end
end
