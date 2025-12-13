defmodule AccumulatorWeb.DailyDashboardLive do
  use AccumulatorWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Daily Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      Daily dashboard
    </div>
    """
  end
end
