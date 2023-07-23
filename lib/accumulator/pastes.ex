defmodule Accumulator.Pastes do
  import Ecto.Query
  alias Accumulator.{Pastes.Paste, Repo}

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
    cleanup_expired_pastes()
    query = from(p in Paste, select: [:id, :title, :expire_at], order_by: [desc: :id])
    Repo.all(query)
  end

  def get_paste(id) do
    case Repo.get(Paste, id) do
      nil ->
        nil

      paste ->
        if expired?(paste) do
          Repo.delete(paste)
          broadcast(:paste_delete)
          nil
        else
          paste
        end
    end
  end

  def delete_paste(id) do
    case Repo.get(Paste, id) do
      nil ->
        nil

      paste ->
        with {:ok, _} <- Repo.delete(paste) do
          broadcast(:paste_delete)
          :ok
        end
    end
  end

  def cleanup_expired_pastes() do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)

    query =
      from(paste in Paste,
        where: paste.expire_at < ^current_date_time,
        select: paste.id
      )

    Repo.delete_all(query)
  end

  def subscribe() do
    Phoenix.PubSub.subscribe(@pubsub, @pubsub_topic)
  end

  defp broadcast(event) do
    Phoenix.PubSub.broadcast(@pubsub, @pubsub_topic, event)
  end

  defp expired?(paste) do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)
    if DateTime.compare(current_date_time, paste.expire_at) == :lt, do: false, else: true
  end
end
