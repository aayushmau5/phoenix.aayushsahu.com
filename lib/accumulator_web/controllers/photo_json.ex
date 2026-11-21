defmodule AccumulatorWeb.PhotoJSON do
  alias Accumulator.Photos.Photo

  def index(%{photos: photos}) do
    %{photos: Enum.map(photos, &data/1)}
  end

  defp data(%Photo{} = photo) do
    base_url = "#{AccumulatorWeb.Endpoint.static_url()}/uploads/photos/#{photo.id}"

    %{
      id: photo.id,
      caption: photo.caption,
      place: photo.place,
      taken_at: photo.taken_at,
      width: photo.width,
      height: photo.height,
      thumb_url: "#{base_url}/thumb.webp",
      full_url: "#{base_url}/full.webp"
    }
  end
end
