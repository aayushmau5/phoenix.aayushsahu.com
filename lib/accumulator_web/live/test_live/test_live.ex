defmodule AccumulatorWeb.TestLive do
  use AccumulatorWeb, :live_view

  def render(assigns) do
    ~H"""
    <.header>
      Hello from test liveview
    </.header>

    <.button type="submit" disabled={true} name="lol">
      Button
    </.button>
    """
  end
end
