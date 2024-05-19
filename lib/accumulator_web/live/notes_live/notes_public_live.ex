defmodule AccumulatorWeb.NotesPublicLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes}

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full max-h-screen font-note relative p-4 flex flex-col">
      <div>
        Workspaces
        <div id="workspaces" class="flex gap-2 mt-2 flex-wrap">
          <div
            :for={workspace <- @workspaces}
            id={"workspace-#{workspace.id}"}
            class="flex gap-2 items-center"
          >
            <button
              class="rounded-md text-sm p-2 bg-zinc-600 hover:bg-opacity-80 disabled:bg-opacity-20"
              phx-click={JS.patch("/notes/public/#{workspace.id}")}
              disabled={@selected_workspace && workspace.id == @selected_workspace.id}
            >
              <%= workspace.title %>
            </button>
          </div>
        </div>
      </div>

      <div :if={!@selected_workspace && @page_error} class="mt-40 text-center text-lg text-red-400">
        Requested workspace either doesn't exist or isn't public!
      </div>

      <button
        :if={@selected_workspace}
        phx-click="more-notes"
        class="block text-sm opacity-60 ml-auto"
      >
        Load more
      </button>

      <%!-- Notes UI --%>
      <div
        :if={@selected_workspace}
        class="bg-black bg-opacity-20 p-2 rounded-md overflow-y-auto"
        id="notes"
        phx-update="stream"
        phx-hook="ScrollToBottom"
      >
        <div :for={{dom_id, [date, notes]} <- @streams.notes} id={dom_id}>
          <div class="leading-10 font-bold">
            <%= date %> (<%= Accumulator.Helpers.days_ago(date) %>)
          </div>
          <div :for={note <- notes} class="my-1 bg-[#3d3d3d] p-2 rounded-md" id={"note-#{note.id}"}>
            <article :if={note.text} class="note-text break-words">
              <%= Earmark.as_html!(note.text, escape: false, compact_output: false)
              |> Phoenix.HTML.raw() %>
            </article>
            <div class="text-xs opacity-40 mt-2">
              <.local_time id={"note-#{note.id}-date"} date={note.updated_at} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream_configure(:notes, dom_id: &Enum.at(&1, 0))
     |> stream(:notes, [])
     |> assign(
       page_title: "Notes",
       workspaces: Notes.get_public_workspaces(),
       selected_workspace: nil,
       search: to_form(%{"search" => ""}),
       page_error: nil
     ), layout: {AccumulatorWeb.Layouts, :note}}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    workspace_id = Map.get(params, "id")

    socket =
      if workspace_id == "default" do
        handle_default_route(socket)
      else
        handle_workspace(workspace_id, socket)
      end

    {:noreply, socket}
  end

  def handle_default_route(socket) do
    workspaces = socket.assigns.workspaces

    case Enum.at(workspaces, 0) do
      nil ->
        socket |> assign(page_error: :no_workspace)

      workspace ->
        socket
        |> assign_notes(workspace)
        |> assign(
          selected_workspace: workspace,
          page_error: nil
        )
    end
  end

  def handle_workspace(workspace_id, socket) do
    workspace =
      case Integer.parse(workspace_id) do
        {id, ""} -> Notes.get_workspace(id)
        _ -> nil
      end

    case workspace do
      nil ->
        assign(socket, page_error: :no_workspace)

      workspace ->
        if workspace.is_public do
          socket
          |> assign_notes(workspace)
          |> assign(
            selected_workspace: workspace,
            page_error: nil
          )
        else
          assign(socket, page_error: :not_public_workspace)
        end
    end
  end

  @impl true
  def handle_event("more-notes", _params, socket) do
    start_date = socket.assigns.pagination_date
    workspace_id = socket.assigns.selected_workspace.id

    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(workspace_id, start_date)

    socket =
      socket
      |> assign(pagination_date: pagination_date)
      |> stream(:notes, Enum.reverse(notes), at: 0)

    {:noreply, socket}
  end

  defp assign_notes(socket, workspace) do
    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(
        workspace.id,
        Notes.get_utc_datetime_from_date()
      )

    socket
    |> stream(:notes, notes, reset: true)
    |> assign(pagination_date: pagination_date)
    |> push_event("new-note-scroll", %{})
  end
end
