defmodule Accumulator.Pastes do
  import Ecto.Query
  alias Accumulator.{Pastes.Paste, Repo, Helpers}
  alias PubSubContract.Bus
  alias Accumulator.PubSub.Messages.Paste, as: PasteMsg

  # TODO: add tests

  @pubsub Accumulator.PubSub

  def add_paste(changeset) do
    with {:ok, _record} <- Repo.insert(changeset) do
      Bus.publish(@pubsub, %PasteMsg.Created{})
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
          if Map.get(paste, :storage_directory) != nil do
            cleanup_dir(paste.storage_directory)
          end

          Bus.publish(@pubsub, %PasteMsg.Deleted{})
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

    get_expired_pastes_dir(current_date_time)
    |> Enum.map(fn dir ->
      if dir != nil, do: cleanup_dir(dir)
    end)

    query =
      from(paste in Paste,
        where: paste.expire_at < ^current_date_time
      )

    Repo.delete_all(query)
    Bus.publish(@pubsub, %PasteMsg.Deleted{})
  end

  def subscribe() do
    Bus.subscribe(@pubsub, PasteMsg.Created)
  end

  def cleanup_files(files) do
    Enum.map(files, &delete_file(&1))
  end

  def create_storage_dir() do
    storage_directory_uuid = Ecto.UUID.generate()

    storage_directory =
      Path.join([Application.fetch_env!(:accumulator, :upload_dir), storage_directory_uuid])

    :ok = File.mkdir(storage_directory)
    storage_directory
  end

  defp get_expired_pastes_dir(current_date_time) do
    query =
      from(paste in Paste,
        where: paste.expire_at < ^current_date_time,
        select: paste.storage_directory
      )

    Repo.all(query)
  end

  defp cleanup_dir(dir) do
    {:ok, _} = File.rm_rf(dir)
  end

  defp delete_file(%{storage_path: path} = _file) do
    File.rm(path)
  end
end
