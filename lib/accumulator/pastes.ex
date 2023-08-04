defmodule Accumulator.Pastes do
  import Ecto.Query
  alias Accumulator.{Pastes.Paste, Repo, Helpers}

  # TODO: add tests

  @pubsub Accumulator.PubSub
  @pubsub_topic "paste_event"

  def add_paste(changeset) do
    with {:ok, _record} <- Repo.insert(changeset) do
      broadcast(:new_paste)
      :ok
    end
  end

  def get_all_pastes() do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)

    query =
      from(paste in Paste,
        where: paste.expire_at > ^current_date_time,
        select: paste,
        order_by: [desc: paste.id]
      )

    Repo.all(query)
  end

  def get_paste(id) do
    case Repo.get(Paste, id) do
      nil ->
        nil

      paste ->
        if Helpers.date_passed?(paste.expire_at), do: nil, else: paste
    end
  end

  def delete_paste(id) do
    case Repo.get(Paste, id) do
      nil ->
        nil

      paste ->
        with {:ok, _} <- Repo.delete(paste) do
          cleanup_files(paste.files)
          broadcast(:paste_delete)
          :ok
        end
    end
  end

  def update_existing_paste(changeset) do
    Repo.insert(
      changeset,
      on_conflict: :replace_all,
      conflict_target: [:id]
    )
  end

  def cleanup_expired_pastes() do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)

    get_expired_pastes_files(current_date_time) |> Enum.map(&cleanup_files(&1))

    query =
      from(paste in Paste,
        where: paste.expire_at < ^current_date_time
      )

    Repo.delete_all(query)
    broadcast(:paste_delete)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, @pubsub_topic)
  end

  def cleanup_files(files) do
    Enum.map(files, &delete_file(&1))
  end

  defp broadcast(event) do
    Phoenix.PubSub.broadcast(@pubsub, @pubsub_topic, event)
  end

  defp get_expired_pastes_files(current_date_time) do
    query =
      from(paste in Paste,
        where: paste.expire_at < ^current_date_time,
        select: paste.files
      )

    Repo.all(query)
  end

  defp delete_file(%{storage_path: path} = _file) do
    File.rm(path)
  end
end
