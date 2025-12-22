defmodule AccumulatorWeb.BinLive.Home do
  use AccumulatorWeb, :live_view

  alias Accumulator.Pastes

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="mb-3 text-xl font-bold">LiveBin</h1>

      <.link
        class="flex items-center gap-1 w-max mb-5 p-2 bg-opacity-80 bg-[#116a34] hover:bg-opacity-70"
        navigate={~p"/bin/create"}
      >
        <Heroicons.plus class="h-4" />
      </.link>

      <%= case @pastes do %>
        <% nil -> %>
          <div>Loading...</div>
        <% [] -> %>
          <div>No pastes present.</div>
        <% pastes -> %>
          <.link
            :for={paste <- pastes}
            class="block mb-2 p-2 hover:bg-[#373739]"
            navigate={~p"/bin/#{paste.id}/show"}
          >
            <div>{paste.title}</div>
            <div>
              Expires at: <.local_time id={"paste-expire-time-#{paste.id}"} date={paste.expire_at} />
            </div>
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

    {:ok, assign(socket, page_title: "LiveBin", pastes: pastes)}
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
