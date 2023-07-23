defmodule AccumulatorWeb.BinLive.Home do
  use AccumulatorWeb, :live_view

  alias Accumulator.Pastes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="mb-5 text-xl font-bold">LiveBin</h1>

      <.link
        class="inline-block mb-5 border border border-white px-2 py-1 rounded-md hover:opacity-70"
        navigate={~p"/bin/create"}
      >
        Create
      </.link>

      <%= case @pastes do %>
        <% nil -> %>
          <div>Loading...</div>
        <% [] -> %>
          <div>No pastes present</div>
        <% pastes -> %>
          <.link
            :for={paste <- pastes}
            class="block border mb-2 p-2 rounded-md hover:bg-slate-700 hover:border-slate-500"
            navigate={~p"/bin/#{paste.id}/show"}
          >
            <div><%= paste.title %></div>
            <div>Expires at: <.local_time id="paste-expire-time" date={paste.expire_at} /></div>
          </.link>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    pastes =
      if connected?(socket) do
        Pastes.subscribe()
        Pastes.get_all_pastes()
      end

    {:ok, assign(socket, pastes: pastes)}
  end

  @impl true
  def handle_info(:new_paste, socket) do
    {:noreply, assign(socket, pastes: Pastes.get_all_pastes())}
  end

  @impl true
  def handle_info(:paste_delete, socket) do
    {:noreply, assign(socket, pastes: Pastes.get_all_pastes())}
  end
end
