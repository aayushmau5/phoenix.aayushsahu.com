defmodule AccumulatorWeb.DashboardComponents do
  @moduledoc """
  Components for dashboard.
  """
  use Phoenix.Component

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def square(assigns) do
    ~H"""
    <div class={["p-2 border-2 border-zinc-600", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil
  attr :href, :string, required: true
  slot :inner_block, required: true

  def external_link(assigns) do
    ~H"""
    <a class={@class} href={@href} target="_blank" rel="noreferrer">
      {render_slot(@inner_block)}
    </a>
    """
  end
end
