defmodule Accumulator.Photos.Processor do
  @moduledoc """
  Turns an uploaded photo into the WebP files the site serves.

  Writes `full.webp` and `thumb.webp` into the given directory. Metadata is
  stripped from both, so GPS and camera details never leave the server.
  """

  def process(source_path, dest_dir) do
    with {:ok, image} <- Image.open(source_path),
         :ok <- File.mkdir_p(dest_dir),
         {:ok, full_image} <- write_sizes(source_path, dest_dir) do
      {:ok,
       %{
         taken_at: taken_at(image),
         width: Image.width(full_image),
         height: Image.height(full_image)
       }}
    end
  end

  defp write_sizes(source_path, dest_dir) do
    with {:ok, full_image} <- write_size(source_path, Path.join(dest_dir, "full.webp"), 2048),
         {:ok, _thumb_image} <- write_size(source_path, Path.join(dest_dir, "thumb.webp"), 600) do
      {:ok, full_image}
    end
  end

  defp write_size(source_path, dest_path, length) do
    with {:ok, image} <- Image.thumbnail(source_path, length, resize: :down) do
      Image.write(image, dest_path, quality: 80, strip_metadata: true)
    end
  end

  defp taken_at(image) do
    case Image.exif(image) do
      {:ok, %{exif: %{datetime_original: %NaiveDateTime{} = naive}}} ->
        DateTime.from_naive!(naive, "Etc/UTC")

      _ ->
        DateTime.utc_now(:second)
    end
  end
end
