defmodule AccumulatorWeb.DevicesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Stats
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Devices")
     |> assign(:ua_stats, AsyncResult.loading())
     |> start_async(:load_ua_stats, fn -> Stats.get_user_agent_stats() end)}
  end

  @impl true
  def handle_async(:load_ua_stats, {:ok, stats}, socket) do
    browser_counts = aggregate_by(stats, :browser)
    os_counts = aggregate_by(stats, :os)
    device_counts = aggregate_by(stats, :device)
    total = Enum.reduce(stats, 0, fn s, acc -> acc + s.count end)

    {:noreply,
     assign(socket,
       ua_stats: AsyncResult.ok(stats),
       browser_counts: browser_counts,
       os_counts: os_counts,
       device_counts: device_counts,
       total: total
     )}
  end

  defp aggregate_by(stats, key) do
    stats
    |> Enum.group_by(&Map.get(&1, key))
    |> Enum.map(fn {name, entries} -> {name, Enum.reduce(entries, 0, fn s, acc -> acc + s.count end)} end)
    |> Enum.sort_by(fn {_, count} -> count end, :desc)
  end

  defp percentage(count, total) when total > 0, do: Float.round(count / total * 100, 1)
  defp percentage(_, _), do: 0.0

  @impl true
  def render(assigns) do
    ~H"""
    <.back navigate={~p"/dashboard"}>Dashboard</.back>

    <.header class="mb-4" h1_class="text-xl">
      Devices & Browsers
    </.header>

    <.async_result :let={_stats} assign={@ua_stats}>
      <:loading>Loading device stats...</:loading>
      <:failed :let={_failure}>There was an error loading device stats</:failed>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <.breakdown_section title="Browsers" items={@browser_counts} total={@total} />
        <.breakdown_section title="Operating Systems" items={@os_counts} total={@total} />
        <.breakdown_section title="Devices" items={@device_counts} total={@total} />
      </div>

      <h3 class="text-lg font-semibold mb-3">All Combinations</h3>
      <div class="overflow-y-auto">
        <table class="w-full">
          <thead class="text-left text-[0.8125rem] leading-6 text-zinc-500">
            <tr>
              <th class="p-0 pb-4 pr-6 font-normal">Browser</th>
              <th class="p-0 pb-4 pr-6 font-normal">OS</th>
              <th class="p-0 pb-4 pr-6 font-normal">Device</th>
              <th class="p-0 pb-4 pr-6 font-normal text-right">Visits</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-zinc-800 border-t border-zinc-800 text-sm leading-6 text-white">
            <tr :for={stat <- @ua_stats.result} class="group hover:bg-[#0f4e28]">
              <td class="py-3 pr-6">{stat.browser}</td>
              <td class="py-3 pr-6">{stat.os}</td>
              <td class="py-3 pr-6">{stat.device}</td>
              <td class="py-3 pr-6 text-right">{stat.count}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </.async_result>
    """
  end

  defp breakdown_section(assigns) do
    ~H"""
    <div>
      <h3 class="text-lg font-semibold mb-3">{@title}</h3>
      <div class="space-y-2">
        <div :for={{name, count} <- @items}>
          <div class="flex justify-between text-sm mb-1">
            <span>{name}</span>
            <span class="text-zinc-400">{count} ({percentage(count, @total)}%)</span>
          </div>
          <div class="w-full bg-zinc-800 h-2">
            <div class="bg-[#116a34] h-2" style={"width: #{percentage(count, @total)}%"}></div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
