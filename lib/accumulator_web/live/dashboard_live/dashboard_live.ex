defmodule AccumulatorWeb.DashboardLive do
  use AccumulatorWeb, :live_view

  import AccumulatorWeb.DashboardComponents
  alias AccumulatorWeb.Presence

  @impl true
  def mount(_params, _session, socket) do
    # TODO: Need to decide on how to get rt updates when anything changes
    # TODO: better assign naming
    socket =
      if connected?(socket) do
        assign(socket,
          total_page_views: Accumulator.get_total_website_views(),
          current_page_view_count:
            Presence.list("user-join") |> Map.get("", %{metas: []}) |> Map.get(:metas) |> length(),
          blogs_data: Accumulator.generate_blog_data()
        )
      else
        assign(socket, total_page_views: 0, blogs_data: [], current_page_view_count: 0)
      end

    {:ok,
     socket
     |> assign(page_title: "Accumulator Dashboard")}
  end
end
