defmodule AccumulatorWeb.ContactChannel do
  use Phoenix.Channel

  alias Accumulator.Contact

  @impl true
  def join("contact", _params, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_in("new_contact", %{"email" => email, "message" => message}, socket) do
    attrs = %{
      email: email,
      message: message
    }

    case Contact.create_message(attrs) do
      {:ok, contact_message} ->
        {:reply, {:ok, %{status: "success", id: contact_message.id}}, socket}

      {:error, changeset} ->
        {:reply, {:error, %{errors: format_errors(changeset)}}, socket}
    end
  end

  # Private helper functions

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
