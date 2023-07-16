defmodule AccumulatorWeb.SyncLive do
  use AccumulatorWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    Protected route
    """
  end
end
