defmodule Accumulator.Photos do
  import Ecto.Query
  alias Accumulator.Repo
  alias Accumulator.Photos.Photo

  def list_photos do
    from(p in Photo, order_by: [desc: p.taken_at, desc: p.id])
    |> Repo.all()
  end

  def get_photo!(id), do: Repo.get!(Photo, id)

  def create_photo(attrs \\ %{}) do
    %Photo{}
    |> Photo.changeset(attrs)
    |> Repo.insert()
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
    Repo.delete(photo)
  end
end
