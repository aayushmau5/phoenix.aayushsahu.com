defmodule AccumulatorWeb.BinComponents do
  use Phoenix.Component

  attr :paste, :map, required: true
  slot :inner_block, required: true

  def render_or_show_error(assigns) do
    ~H"""
    <%= case @paste do %>
      <% nil -> %>
        <div class="text-xl text-center font-bold">
          No paste found! It either expired or doesn't exist.
        </div>
      <% :error -> %>
        <div class="text-xl text-center font-bold">Invalid paste id provided.</div>
      <% _paste -> %>
        <div>
          <%= render_slot(@inner_block) %>
        </div>
    <% end %>
    """
  end
end
