defmodule Accumulator.Spotify do
  @moduledoc """
  Get top tracks and current playing from spotify
  """

  @access_token_key "spotify:access_token"
  @refresh_token_key "spotify:refresh_token"
  @now_playing_key "spotify:now_playing"
  @top_tracks_key "spotify:top_tracks"
  @top_artists_key "spotify:top_artists"
  @now_playing_expire 300
  @top_tracks_expire 86_400
  @top_artists_expire 86_400

  alias Accumulator.Spotify.{API, Helpers}

  @doc """
  Get current playing track information
  """
  @spec get_now_playing() ::
          {:ok, Helpers.track()} | {:not_playing, String.t()} | {:error, String.t()}
  def get_now_playing() do
    case Redix.command(:redix, ["GET", @now_playing_key]) do
      {:ok, nil} ->
        get_and_cache_now_playing()

      {:ok, now_playing} ->
        {:ok, Jason.decode!(now_playing)}

      error ->
        error
    end
  end

  @doc """
  Get top tracks information
  """
  @spec get_top_tracks() :: {:ok, [Helpers.track()]} | {:error, String.t() | any()}
  def get_top_tracks() do
    case Redix.command(:redix, ["GET", @top_tracks_key]) do
      {:ok, nil} ->
        get_and_cache_top_tracks()

      {:ok, top_tracks} ->
        {:ok, Jason.decode!(top_tracks)}

      error ->
        error
    end
  end

  @doc """
  Get top artists information
  """
  @spec get_top_artists() :: {:ok, [Helpers.artist()]} | {:error, String.t() | any()}
  def get_top_artists() do
    case Redix.command(:redix, ["GET", @top_artists_key]) do
      {:ok, nil} ->
        get_and_cache_top_artists()

      {:ok, top_artists} ->
        {:ok, Jason.decode!(top_artists)}

      error ->
        error
    end
  end

  defp get_and_cache_now_playing do
    with {:ok, access_token} <- get_access_token(),
         {:ok, response} <- API.now_playing(access_token) do
      case response.status do
        200 ->
          currently_playing =
            Helpers.process_currently_playing(response.body["item"])

          stringified_currently_playing = Jason.encode!(currently_playing)

          {:ok, _} =
            Redix.command(:redix, [
              "SET",
              @now_playing_key,
              stringified_currently_playing,
              "EX",
              @now_playing_expire
            ])

          {:ok, currently_playing}

        204 ->
          {:not_playing, "Nothing playing at the moment"}

        401 ->
          with {:ok, _} <- refresh_access_token() do
            get_and_cache_now_playing()
          end

        _ ->
          {:error, response.body}
      end
    end
  end

  defp get_and_cache_top_tracks do
    with {:ok, access_token} <- get_access_token(),
         {:ok, response} <- API.top_tracks(access_token) do
      case response.status do
        200 ->
          top_tracks = Helpers.process_top_tracks(response.body["items"])
          stringified_top_tracks = Jason.encode!(top_tracks)

          {:ok, _} =
            Redix.command(:redix, [
              "SET",
              @top_tracks_key,
              stringified_top_tracks,
              "EX",
              @top_tracks_expire
            ])

          {:ok, top_tracks}

        401 ->
          with {:ok, _} <- refresh_access_token() do
            get_and_cache_top_tracks()
          end

        _ ->
          {:error, response.body}
      end
    end
  end

  defp get_and_cache_top_artists do
    with {:ok, access_token} <- get_access_token(),
         {:ok, response} <- API.top_artists(access_token) do
      case response.status do
        200 ->
          top_artists = Helpers.process_top_artists(response.body["items"])
          stringified_top_artists = Jason.encode!(top_artists)

          {:ok, _} =
            Redix.command(:redix, [
              "SET",
              @top_artists_key,
              stringified_top_artists,
              "EX",
              @top_artists_expire
            ])

          {:ok, top_artists}

        401 ->
          with {:ok, _} <- refresh_access_token() do
            get_and_cache_top_artists()
          end

        _ ->
          {:error, response.body}
      end
    end
  end

  defp get_access_token do
    case Redix.command(:redix, ["GET", @access_token_key]) do
      {:ok, nil} -> refresh_access_token()
      {:ok, token} -> {:ok, token}
      {:error, reason} -> {:error, reason}
    end
  end

  defp refresh_access_token do
    refresh_token = get_refresh_token_from_redis()
    {client_id, client_secret} = get_client_id_and_secret()

    response =
      API.refresh_access_token(client_id, client_secret, refresh_token)

    case response do
      {:ok, response} ->
        if response.status == 200 do
          access_token = response.body["access_token"]
          expire = response.body["expires_in"]
          {:ok, _} = Redix.command(:redix, ["SET", @access_token_key, access_token, "EX", expire])
          {:ok, access_token}
        else
          {:error, "Cannot refresh token"}
        end

      error ->
        error
    end
  end

  defp get_refresh_token_from_redis do
    case Redix.command(:redix, ["GET", @refresh_token_key]) do
      {:ok, nil} -> raise("Refresh token not present")
      {:ok, token} -> token
      {:error, reason} -> raise(reason)
    end
  end

  defp get_client_id_and_secret do
    id = System.get_env("SPOTIFY_CLIENT_ID")
    secret = System.get_env("SPOTIFY_CLIENT_SECRET")
    {id, secret}
  end
end
