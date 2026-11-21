defmodule Accumulator.Photos do
  import Ecto.Query
  alias Accumulator.Repo
  alias Accumulator.Photos.{Photo, Processor}

  def list_photos do
    from(p in Photo, order_by: [desc: p.taken_at, desc: p.id])
    |> Repo.all()
  end

  def get_photo!(id), do: Repo.get!(Photo, id)

  def create_photo(source_path, attrs \\ %{}) do
    staging_dir = Path.join(photos_dir(), ".staging-" <> Ecto.UUID.generate())

    with {:ok, meta} <- Processor.process(source_path, staging_dir),
         {:ok, photo} <- insert_and_move(staging_dir, meta, attrs) do
      {:ok, photo}
    else
      error ->
        File.rm_rf(staging_dir)
        error
    end
  end

  def update_photo_details(%Photo{} = photo, attrs) do
    photo
    |> Photo.details_changeset(attrs)
    |> Repo.update()
  end

  def change_photo_details(%Photo{} = photo, attrs \\ %{}) do
    Photo.details_changeset(photo, attrs)
  end

  def delete_photo(%Photo{} = photo) do
    with {:ok, photo} <- Repo.delete(photo) do
      File.rm_rf(photo_dir(photo))
      {:ok, photo}
    end
  end

  def photos_dir do
    Path.join(Application.fetch_env!(:accumulator, :upload_dir), "photos")
  end

  def photo_dir(%Photo{id: id}), do: Path.join(photos_dir(), to_string(id))

  defp insert_and_move(staging_dir, meta, attrs) do
    Repo.transaction(fn ->
      with {:ok, photo} <- insert_photo(meta, attrs),
           :ok <- File.rename(staging_dir, photo_dir(photo)) do
        photo
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp insert_photo(meta, attrs) do
    %Photo{taken_at: meta.taken_at, width: meta.width, height: meta.height}
    |> Photo.changeset(attrs)
    |> Repo.insert()
  end
end
