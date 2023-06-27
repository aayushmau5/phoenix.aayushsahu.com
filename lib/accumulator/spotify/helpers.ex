defmodule Accumulator.Spotify.Helpers do
  @moduledoc """
  Helpers to work with Spotify API response
  """

  @type t :: %{
          name: String.t(),
          album_image_url: String.t(),
          album_name: String.t(),
          artists: [String.t()]
        }

  @spec process_currently_playing(any()) :: t()
  def process_currently_playing(track) do
    %{
      "name" => track["name"],
      "album_image_url" => get_image_url(track),
      "album_name" => track["album"]["name"],
      "artists" => get_artists_name(track)
    }
  end

  @spec process_top_tracks(any()) :: [t()]
  def process_top_tracks(tracks) do
    Enum.map(tracks, fn track ->
      %{
        "name" => track["name"],
        "album_image_url" => get_image_url(track),
        "album_name" => track["album"]["name"],
        "artists" => get_artists_name(track)
      }
    end)
  end

  defp get_image_url(track) do
    images = track["album"]["images"]
    first_image = Enum.at(images, 0)
    first_image["url"]
  end

  defp get_artists_name(track) do
    artists = track["artists"]
    Enum.map(artists, fn artist -> artist["name"] end) |> Enum.join(", ")
  end
end
