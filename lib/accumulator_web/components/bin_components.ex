defmodule AccumulatorWeb.BinComponents do
  use Phoenix.Component

  # TODO: add create form here and fix the validation

  attr :paste, :map, required: true
  attr :title, :string
  slot :inner_block, required: true

  # TODO: refactor this component
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
          <h1 :if={@title} class="text-center text-xl font-bold"><%= @title %></h1>
          <%= render_slot(@inner_block) %>
        </div>
    <% end %>
    """
  end
end
