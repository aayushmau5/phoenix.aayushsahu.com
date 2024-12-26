defmodule AccumulatorWeb.SessionsLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Auth

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-lg font-bold">Sessions</h1>
      <div :for={session <- @sessions} class="mt-2 bg-black bg-opacity-10 p-2 rounded-md">
        <div>
          Login at:
          <.local_time
            date={DateTime.from_naive!(session.inserted_at, "Etc/UTC")}
            id={"time-#{session.id}"}
          />
        </div>
        <div>IP: {session.ip_address}</div>
        <div>Location: {session.location}</div>
        <div>Device: {session.device_info}</div>
        <button
          phx-click="delete-session"
          phx-value-id={session.id}
          class="bg-gray-700 rounded-md px-2 py-1 text-sm mt-2"
        >
          Delete
        </button>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    sessions = Auth.get_all_sessions()
    {:ok, socket |> assign(sessions: sessions)}
  end

  @impl true
  def handle_event("delete-session", %{"id" => id}, socket) do
    session_id = String.to_integer(id)
    Auth.delete_session_by_id(session_id)

    sessions = Auth.get_all_sessions()
    {:noreply, socket |> assign(sessions: sessions)}
  end
end
