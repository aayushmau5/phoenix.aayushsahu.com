defmodule AccumulatorWeb.BinComponents do
  use Phoenix.Component
  import AccumulatorWeb.CoreComponents

  attr :paste, :map, required: true
  attr :form, :map, required: true
  attr :submit_disabled, :boolean, required: true

  # TODO: add create form here and fix the validation

  def edit_form(assigns) do
    ~H"""
    <.simple_form for={@form} id="paste_form" phx-submit="update_paste" phx-change="validate_paste">
      <.input field={@form[:title]} type="text" id="paste_title" label="Title" required />
      <.input field={@form[:content]} type="textarea" id="paste_content" label="Content" required />

      <div>Expires at: <.local_time id="paste-expire-time" date={@paste.expire_at} /></div>

      <.input
        field={@form[:time_duration]}
        type="number"
        id="paste_expire_duration"
        label="Extend Expire Duration"
        required
      />
      <.input
        field={@form[:time_type]}
        type="select"
        id="paste_expire_type"
        label="Expire Type"
        options={["minute", "hour", "day"]}
        required
      />
      <:actions>
        <.button class="disabled:bg-red-400" disabled={@submit_disabled} phx-disable-with="Saving...">
          Save
        </.button>
      </:actions>
    </.simple_form>
    """
  end

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
