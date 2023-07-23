defmodule AccumulatorWeb.BinLive.Show do
  use AccumulatorWeb, :live_view

  alias Accumulator.Pastes

  # TODO: add copy button for content

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-2 text-xl font-bold">LiveBin</div>

      <.back navigate={~p"/bin"}>
        Back
      </.back>

      <%= if @is_loading do %>
        <div>Loading...</div>
      <% else %>
        <%= case @paste do %>
          <% nil -> %>
            <div class="text-xl text-center font-bold">
              No paste found! It either expired or doesn't exist.
            </div>
          <% :error -> %>
            <div class="text-xl text-center font-bold">Invalid paste id provided.</div>
          <% paste -> %>
            <div>
              <div class="mt-4 text-xl font-bold"><%= paste.title %></div>
              <div class="my-5 border p-2 rounded-md">
                <%= paste.content %>
              </div>
              <div>Expires at: <.local_time id="paste-expire-time" date={paste.expire_at} /></div>

              <button
                phx-click="delete"
                class="mt-5 border border border-white px-2 py-1 rounded-md hover:opacity-70"
              >
                Delete
              </button>
            </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    paste = show_paste(socket, params)

    {:ok, assign(socket, paste: paste, is_loading: !connected?(socket))}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    paste_id = socket.assigns.paste.id

    socket =
      case Pastes.delete_paste(paste_id) do
        {:error, _} -> put_flash(socket, :error, "Failed to delete paste")
        _ -> push_navigate(socket, to: "/bin")
      end

    {:noreply, socket}
  end

  defp show_paste(socket, params) do
    paste_id = Map.get(params, "id")

    if connected?(socket) do
      case Integer.parse(paste_id) do
        {id, ""} -> Pastes.get_paste(id)
        {_, _} -> :error
        :error -> :error
      end
    end
  end
end
