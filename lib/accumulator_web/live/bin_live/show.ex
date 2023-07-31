defmodule AccumulatorWeb.BinLive.Show do
  use AccumulatorWeb, :live_view

  alias Accumulator.Pastes

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
              <div>Expires at: <.local_time id="paste-expire-time" date={paste.expire_at} /></div>
              <div class="flex gap-2">
                <button
                  disabled={!@enable_edit}
                  phx-click="edit"
                  class="flex w-max items-center gap-1 mt-2 px-2 py-1 rounded-md bg-slate-800 hover:bg-slate-700 disabled:opacity-30"
                >
                  <Heroicons.pencil_square class="h-5" /> Edit
                </button>
                <button
                  phx-click="delete"
                  class="flex w-max items-center gap-1 mt-2 px-2 py-1 rounded-md bg-slate-800 hover:bg-slate-700"
                >
                  <Heroicons.trash class="h-5" /> Delete
                </button>
              </div>
              <button
                phx-click={JS.dispatch("phx:copy", to: "#copy-content")}
                class="flex w-max items-center gap-1 text-sm ml-auto my-2 px-2 py-1 rounded-md bg-slate-800 hover:bg-slate-700"
              >
                <Heroicons.clipboard class="h-5" /> <span id="copy-button-text">Copy</span>
              </button>
              <pre
                id="copy-content"
                class="overflow-auto font-inherit max-h-96 mb-5 bg-slate-800 p-2 rounded-md"
              ><%= paste.content %></pre>
            </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    paste = show_paste(socket, params)
    title = page_title(socket, paste) <> " | LiveBin"

    if connected?(socket) and paste not in [nil, :error] do
      Phoenix.PubSub.subscribe(Accumulator.PubSub, "paste_updates:#{paste.id}")
    end

    {:ok,
     assign(socket,
       page_title: title,
       paste: paste,
       enable_edit: true,
       is_loading: !connected?(socket)
     )}
  end

  @impl true
  def handle_event("edit", _params, socket) do
    paste_id = socket.assigns.paste.id
    {:noreply, push_navigate(socket, to: "/bin/#{paste_id}/edit")}
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

  @impl true
  def handle_info(%{event: :edit, count: count}, socket) do
    enable_edit = if count == 0, do: true, else: false
    {:noreply, assign(socket, enable_edit: enable_edit)}
  end

  @impl true
  def handle_info(%{event: :paste_update}, socket) do
    updated_paste = Pastes.get_paste(socket.assigns.paste.id)
    {:noreply, assign(socket, paste: updated_paste)}
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

  defp page_title(socket, paste) do
    if connected?(socket) do
      case paste do
        :error -> "Error"
        %{title: title} -> title
      end
    else
      "Loading..."
    end
  end
end
