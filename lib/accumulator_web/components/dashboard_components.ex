defmodule AccumulatorWeb.DashboardComponents do
  @moduledoc """
  Components for dashboard.
  """
  use Phoenix.Component
  alias AccumulatorWeb.DashboardComponents, as: Component

  def square(assigns) do
    ~H"""
    <Component.border>
      Square lol
    </Component.border>
    <Component.border class="my-2">
      Square lol
    </Component.border>
    <Component.border>
      Square lol
    </Component.border>
    """
  end

  attr :class, :string, default: nil
  slot :inner_block, required: true

  def border(assigns) do
    ~H"""
    <div class={["p-3 border border-2 border-zinc-600 rounded-lg", @class]}>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end
end
