defmodule Accumulator.Spotify.Helpers do
  @moduledoc """
  Helpers to work with Spotify API response
  """

  @type track :: %{
          name: String.t(),
          album_image_url: String.t(),
          album_name: String.t(),
          artists: String.t(),
          url: String.t()
        }

  @type artist :: %{
          name: String.t(),
          image_url: String.t(),
          url: String.t()
        }

  @spec process_currently_playing(track :: any()) :: track()
  def process_currently_playing(track) do
    %{
      "name" => track["name"],
      "album_image_url" => get_image_url(track),
      "album_name" => track["album"]["name"],
      "artists" => get_artists_name(track),
      "url" => get_url(track)
    }
  end

  @spec process_top_tracks(tracks :: any()) :: [track()]
  def process_top_tracks(tracks) do
    Enum.map(tracks, fn track ->
      %{
        "name" => track["name"],
        "album_image_url" => get_image_url(track),
        "album_name" => track["album"]["name"],
        "artists" => get_artists_name(track),
        "url" => get_url(track)
      }
    end)
  end

  @spec process_top_artists(artists :: any()) :: [artist()]
  def process_top_artists(artists) do
    Enum.map(artists, fn artist ->
      %{
        "image_url" => get_artist_image_url(artist),
        "name" => artist["name"],
        "url" => get_url(artist)
      }
    end)
  end

  defp get_artist_image_url(artist) do
    first_image = Enum.at(artist["images"], 0)
    first_image["url"]
  end

  defp get_image_url(track) do
    first_image = Enum.at(track["album"]["images"], 0)
    first_image["url"]
  end

  defp get_artists_name(track) do
    Enum.map_join(track["artists"], ", ", fn artist -> artist["name"] end)
  end

  defp get_url(data) do
    data["external_urls"]["spotify"]
  end
end
