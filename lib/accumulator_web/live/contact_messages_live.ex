defmodule AccumulatorWeb.ContactMessagesLive do
  use AccumulatorWeb, :live_view

  alias Accumulator.Contact
  import AccumulatorWeb.DashboardComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(page_title: "Contact Messages")
     |> load_messages()}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    case Contact.get_message(id) do
      nil ->
        # Message already deleted
        {:noreply,
         socket
         |> put_flash(:info, "Message was already deleted")
         |> assign(:delete_id, nil)
         |> load_messages()}

      message ->
        case Contact.delete_message(message) do
          {:ok, _} ->
            {:noreply,
             socket
             |> put_flash(:info, "Message deleted successfully")
             |> assign(:delete_id, nil)
             |> load_messages()}

          {:error, _changeset} ->
            {:noreply,
             socket
             |> put_flash(:error, "Failed to delete message")
             |> assign(:delete_id, nil)}
        end
    end
  end

  @impl true
  def handle_event("confirm-delete", %{"id" => id}, socket) do
    {:noreply, assign(socket, :delete_id, id)}
  end

  @impl true
  def handle_event("cancel-delete", _, socket) do
    {:noreply, assign(socket, :delete_id, nil)}
  end

  defp load_messages(socket) do
    messages =
      Contact.list_messages()
      |> Enum.map(fn message ->
        # Convert naive datetime to UTC datetime for proper timezone handling
        utc_datetime = DateTime.from_naive!(message.inserted_at, "Etc/UTC")
        %{message | inserted_at: utc_datetime}
      end)

    assign(socket, :messages, messages)
  end
end
