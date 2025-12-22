defmodule AccumulatorWeb.NotesPublicLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.{Notes, Notes.Workspace}

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
              {workspace.title}
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
            {Accumulator.Helpers.day_of_week_string(date)} {date} ({Accumulator.Helpers.days_ago(date)})
          </div>
          <div :for={note <- notes} class="my-1 bg-[#3d3d3d] p-2 rounded-md" id={"note-#{note.id}"}>
            <article :if={note.text} class="note-text break-words font-sans">
              {Earmark.as_html!(note.text, escape: false, compact_output: false)
              |> Phoenix.HTML.raw()}
            </article>
            <div class="text-xs opacity-40 mt-2">
              <.local_time id={"note-#{note.id}-date"} date={note.inserted_at} />
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Notes.subscribe()
    end

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
        |> assign_notes(workspace.id)
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
          |> assign_notes(workspace.id)
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

  @impl true
  def handle_info(%{type: event_type, workspace_id: workspace_id}, socket) do
    workspace_id =
      if is_binary(workspace_id), do: String.to_integer(workspace_id), else: workspace_id

    socket =
      if public_workspace?(workspace_id, socket) do
        handle_changes(event_type, workspace_id, socket)
      else
        socket
      end

    {:noreply, socket}
  end

  defp handle_changes(event_type, workspace_id, socket)
       when event_type in [:new_note, :update_note, :delete_note] do
    if selected_workspace?(workspace_id, socket) do
      notes =
        Notes.get_notes_grouped_and_ordered_till_date(
          workspace_id,
          socket.assigns.pagination_date
        )

      socket
      |> stream(:notes, notes, reset: true)
    else
      socket
    end
  end

  defp handle_changes(:new_workspace, _workspace_id, socket) do
    assign(socket, workspaces: Notes.get_public_workspaces())
  end

  defp handle_changes(:update_workspace, workspace_id, socket) do
    workspaces = Notes.get_public_workspaces()
    socket = assign(socket, workspaces: workspaces)

    if not public_workspace?(workspace_id, socket) do
      push_patch(socket, to: "/notes/public/default")
    else
      socket
    end
  end

  defp handle_changes(:delete_workspace, workspace_id, socket) do
    workspaces = Notes.get_public_workspaces()
    socket = assign(socket, workspaces: workspaces)

    if selected_workspace?(workspace_id, socket) do
      selected_workspace = Enum.random(workspaces)

      push_patch(socket, to: "/notes/public/#{selected_workspace.id}")
    else
      socket
    end
  end

  defp assign_notes(socket, workspace_id) do
    {notes, pagination_date} =
      Notes.get_notes_grouped_and_ordered_by_date(
        workspace_id,
        Accumulator.Helpers.get_utc_datetime_from_date()
      )

    socket
    |> stream(:notes, notes, reset: true)
    |> assign(pagination_date: pagination_date)
    |> push_event("new-note-scroll", %{})
  end

  defp public_workspace?(workspace_id, socket) do
    # Look for workspace in assign. if not found, check the db.
    workspaces = socket.assigns.workspaces

    with nil <- Enum.find(workspaces, &(&1.id == workspace_id)),
         %Workspace{} = workspace <- Notes.get_workspace(workspace_id) do
      workspace.is_public
    else
      # handles 2nd clause
      nil -> false
      # handles 1st clause
      _workspace -> true
    end
  end

  defp selected_workspace?(workspace_id, socket) do
    selected_workspace_id = socket.assigns.selected_workspace.id
    selected_workspace_id == workspace_id
  end
end
