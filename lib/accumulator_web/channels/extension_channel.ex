defmodule AccumulatorWeb.ExtensionChannel do
  use AccumulatorWeb, :channel

  alias Accumulator.Extension
  alias AccumulatorWeb.Presence

  @impl true
  def join("extension", %{"browser" => browser, "id" => id} = _payload, socket) do
    send(self(), :after_join)
    {:ok, socket |> assign(:browser, browser) |> assign(:id, id)}
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} =
      Presence.track(socket, "extensions", %{
        browser: socket.assigns.browser,
        id: socket.assigns.id
      })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("tabs", %{"tabs" => tabs} = payload, socket) do
    Extension.add_tabs(socket.assigns.id, tabs)
    # broadcast to listeners
    {:reply, {:ok, payload}, socket}
  end

  def handle_in("bookmark-tab", payload, socket) do
    params = Map.put(payload, "browser_id", socket.assigns.id)

    reply_payload =
      case Extension.add_bookmark(params) do
        {:ok, _} ->
          %{status: "ok"}

        {:error, _} ->
          %{status: "fail"}
      end

    {:reply, {:ok, reply_payload}, socket}
  end

  def handle_in("get-tabs", _payload, socket) do
    tabs = Extension.get_tabs(socket.assigns.id)
    {:reply, {:ok, tabs}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (extension:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end
end
