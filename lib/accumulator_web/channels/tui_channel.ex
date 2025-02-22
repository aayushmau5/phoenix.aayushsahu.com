defmodule AccumulatorWeb.TUIChannel do
  use AccumulatorWeb, :channel

  alias Accumulator.{Pastes, TUI, TUI.Payload}
  alias Accumulator.Pastes.Paste

  @impl true
  def join(_room_id, payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Bin

  def handle_in("bin", %{"action" => "get-all"} = _payload, socket) do
    pastes = Pastes.get_all_pastes()
    response = %TUI{name: "bin", payload: %Payload{action: "get-all", data: pastes}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "new", "data" => data} = _payload, socket) do
    expire_map = Map.get(data, "expire")

    paste_params = %{
      title: Map.get(data, "title"),
      content: Map.get(data, "content"),
      time_duration: Map.get(expire_map, "time"),
      time_type: Map.get(expire_map, "unit") |> String.downcase()
    }

    paste_changeset =
      %Paste{}
      |> Paste.changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        get_expiration_time(paste_params.time_duration, paste_params.time_type)
      )
      |> Ecto.Changeset.put_embed(:files, [])

    data =
      case Pastes.add_paste(paste_changeset) do
        :ok -> %{status: "OK"}
        {:error, _} -> %{status: "ERROR", message: "Failed to create paste"}
      end

    response = %TUI{name: "bin", payload: %Payload{action: "new", data: data}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "delete", "data" => data} = _payload, socket) do
    bin_id = Map.get(data, "id")

    data =
      case Pastes.delete_paste(bin_id) do
        {:error, _} -> %{status: "ERROR", message: "Failed to delete paste"}
        _ -> %{status: "OK"}
      end

    response = %TUI{name: "bin", payload: %Payload{action: "delete", data: data}}
    {:reply, {:ok, response}, socket}
  end

  def handle_in("bin", %{"action" => "edit", "data" => data} = _payload, socket) do
    expire_map = Map.get(data, "expire")

    paste_params =
      %{
        title: Map.get(data, "title"),
        content: Map.get(data, "content"),
        time_duration: Map.get(expire_map, "time"),
        time_type: Map.get(expire_map, "unit") |> String.downcase()
      }

    bin_id = Map.get(data, "id")
    paste = Pastes.get_paste(bin_id)

    deleted_files =
      Map.get(data, "files")
      |> Enum.filter(&(Map.get(&1, "removed") == true))
      |> Enum.map(&Map.get(&1, "file"))

    deleted_files =
      Enum.filter(paste.files, fn file ->
        Enum.any?(deleted_files, fn f -> Map.get(f, "id") == file.id end)
      end)

    present_files =
      Map.get(data, "files")
      |> Enum.filter(&(Map.get(&1, "removed") !== true))
      |> Enum.map(&Map.get(&1, "file"))

    files = update_files(paste.files, present_files)

    updated_paste =
      paste
      |> Paste.update_changeset(paste_params)
      |> Ecto.Changeset.put_change(
        :expire_at,
        extend_expiration_time(
          paste.expire_at,
          paste_params.time_duration,
          paste_params.time_type
        )
      )
      |> Ecto.Changeset.put_embed(:files, files)
      |> Pastes.update_existing_paste()

    data =
      case updated_paste do
        {:ok, paste} ->
          Pastes.cleanup_files(deleted_files)
          paste

        {:error, _} ->
          paste
      end

    response = %TUI{name: "bin", payload: %Payload{action: "edit", data: data}}
    {:reply, {:ok, response}, socket}
  end

  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp get_expiration_time(duration, type) do
    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(DateTime.utc_now(), duration, type) |> DateTime.truncate(:second)
  end

  defp extend_expiration_time(expiration_time, duration, type) do
    type =
      case type do
        "minute" -> :minute
        "hour" -> :hour
        "day" -> :day
      end

    DateTime.add(expiration_time, duration, type) |> DateTime.truncate(:second)
  end

  defp update_files(current_files, present_files) do
    Enum.filter(current_files, fn file ->
      present_file_id?(file.id, present_files)
    end)
  end

  defp present_file_id?(id, present_files) do
    Enum.any?(present_files, fn file -> Map.get(file, "id") == id end)
  end
end
