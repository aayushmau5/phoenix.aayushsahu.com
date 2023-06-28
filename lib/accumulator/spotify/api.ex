defmodule Accumulator.Spotify.API do
  @moduledoc """
  The Spotify API module
  """

  @top_tracks_limit 10
  @top_tracks_offset 0
  @top_artists_limit 10
  @top_artists_offset 0

  @doc """
  Get new access token using refresh token
  """
  @spec refresh_access_token(
          client_id :: String.t(),
          client_secret :: String.t(),
          refresh_token :: String.t()
        ) :: {:ok, Req.Response.t()} | {:error, any()}
  def refresh_access_token(client_id, client_secret, refresh_token) do
    encoded_token = Base.encode64("#{client_id}:#{client_secret}")

    Req.post("https://accounts.spotify.com/api/token",
      body: URI.encode_query(grant_type: "refresh_token", refresh_token: refresh_token),
      headers: [
        {"Content-Type", "application/x-www-form-urlencoded"},
        {"Authorization", "Basic #{encoded_token}"}
      ]
    )
  end

  @doc """
  Get currently playing track
  """
  @spec now_playing(access_token :: String.t()) :: {:ok, Req.Response.t()} | {:error, any()}
  def now_playing(access_token) do
    Req.get(
      "https://api.spotify.com/v1/me/player/currently-playing",
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )

    # {:ok, response} | {:error, reason}
  end

  @doc """
  Get top 10 tracks
  """
  @spec top_tracks(access_token :: String.t()) :: {:ok, Req.Response.t()} | {:error, any()}
  def top_tracks(access_token) do
    Req.get(
      "https://api.spotify.com/v1/me/top/tracks",
      params: [limit: @top_tracks_limit, offset: @top_tracks_offset],
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )
  end

  @doc """
  Get top 10 artists
  """
  @spec top_artists(access_token :: String.t()) :: {:ok, Req.Response.t()} | {:error, any()}
  def top_artists(access_token) do
    Req.get(
      "https://api.spotify.com/v1/me/top/artists",
      params: [limit: @top_artists_limit, offset: @top_artists_offset],
      headers: [{"Authorization", "Bearer #{access_token}"}]
    )
  end
end
