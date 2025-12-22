defmodule AccumulatorWeb.DailyDashboardLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Stats
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, socket) do
    default_stat = "main"

    {:ok,
     socket
     |> assign(page_title: "Daily Dashboard")
     |> assign(stat_name: default_stat)
     |> assign(:stats, AsyncResult.loading())
     |> start_async(:load_stats, fn ->
       Stats.get_daily_stats_for_last_n_days(default_stat, 30)
     end)
     |> assign_async(:all_stats, fn ->
       {:ok,
        %{
          all_stats: %{
            main: Stats.get_main_data(),
            blogs: Stats.get_all_blogs_data()
          }
        }}
     end)
     |> assign(chart: build_chart())}
  end

  @impl true
  def handle_async(:load_stats, {:ok, stats}, socket) do
    %{chart: chart} = socket.assigns
    view_stats = Enum.map(stats, fn s -> [s.date, s.views] end)

    {:noreply,
     socket
     |> assign(:stats, AsyncResult.ok(stats))
     |> LiveCharts.push_update(chart.id, [%{name: "Main", data: view_stats}])}
  end

  @impl true
  def handle_event("select:" <> slug, _params, socket) do
    %{chart: chart} = socket.assigns

    stats = Stats.get_daily_stats_for_last_n_days(slug, 30)

    chart_data =
      if slug == "main" do
        [%{name: "Visitors", data: Enum.map(stats, fn s -> [s.date, s.views] end)}]
      else
        [
          %{name: "Views", data: Enum.map(stats, fn s -> [s.date, s.views] end)},
          %{name: "Likes", data: Enum.map(stats, fn s -> [s.date, s.likes] end)}
        ]
      end

    {:noreply,
     socket
     |> assign(stat_name: slug)
     |> assign(stats: AsyncResult.ok(stats))
     |> LiveCharts.push_update(chart.id, chart_data)}
  end

  defp build_chart() do
    LiveCharts.build(%{
      type: :area,
      series: [],
      options: %{
        colors: ["#0f4e28", "#d9ff36"],
        xaxis: %{
          type: "datetime",
          labels: %{
            style: %{
              colors: "#ffffff"
            }
          }
        },
        yaxis: %{
          min: 0,
          labels: %{
            style: %{
              colors: "#ffffff"
            }
          }
        },
        chart: %{
          animations: %{enabled: true, easing: "linear"},
          zoom: %{enabled: false},
          toolbar: %{show: false}
        },
        dataLabels: %{
          enabled: false
        },
        stroke: %{curve: "smooth"},
        tooltip: %{
          theme: "dark"
        }
      }
    })
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.back navigate={~p"/dashboard"}>Dashboard</.back>
      <.header class="mb-4" h1_class="text-xl">
        Daily stats
      </.header>
      <.async_result :let={_stats} assign={@stats}>
        <:loading>Loading stats...</:loading>
        <:failed :let={_failure}>there was an error loading the stats</:failed>
        <div class="max-w-2xl">
          <LiveCharts.chart chart={@chart} />
        </div>
      </.async_result>

      <.async_result :let={all_stats} assign={@all_stats}>
        <:loading>Loading stats...</:loading>
        <:failed :let={_failure}>there was an error loading the stats</:failed>
        <div id="stats" class="mt-6">
          <h3 class="text-lg font-semibold mb-3">Page Stats</h3>
          <ul class="space-y-2">
            <li
              phx-click="select:main"
              class={"flex items-center justify-between p-2 transition-colors cursor-pointer #{if @stat_name == "main", do: "bg-[#0f4e28]", else: ""}"}
            >
              <span class="font-medium">Visitors</span>
              <span class="flex items-center gap-1 text-sm text-gray-400">
                <span title="Views">Views: {all_stats.main.views}</span>
              </span>
            </li>
            <li
              :for={stat <- all_stats.blogs}
              phx-click={"select:#{stat.slug}"}
              class={"flex items-center justify-between p-2 hover:bg-[#0f4e28] transition-colors cursor-pointer #{if @stat_name == stat.slug, do: "bg-[#0f4e28]", else: ""}"}
            >
              <span class="font-medium truncate">{stat.slug}</span>
              <span class="flex items-center gap-3 text-sm text-gray-400">
                <span title="Views">Views: {stat.views}</span>
                <span title="Likes">Likes: {stat.likes}</span>
              </span>
            </li>
          </ul>
        </div>
      </.async_result>
    </div>
    """
  end
end
