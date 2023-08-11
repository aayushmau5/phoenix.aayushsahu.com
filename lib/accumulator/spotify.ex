defmodule Accumulator.Spotify do
  @moduledoc """
  Get top tracks and current playing from spotify
  """

  import Ecto.Query
  alias Accumulator.Spotify.{API, Helpers, Schema}
  alias Accumulator.Repo

  @access_token_key "access_token"
  @refresh_token_key "refresh_token"
  @now_playing_key "now_playing"
  @top_tracks_key "top_tracks"
  @top_artists_key "top_artists"
  @now_playing_expire 180
  @top_tracks_expire 86_400
  @top_artists_expire 86_400

  @doc """
  Get current playing track information
  """
  @spec get_now_playing() ::
          {:ok, Helpers.track()} | {:not_playing, String.t()} | {:error, String.t()}
  def get_now_playing() do
    case get_data(@now_playing_key) do
      nil ->
        get_and_cache_now_playing()

      %{data: data} ->
        {:ok, Jason.decode!(data)}
    end
  end

  @doc """
  Get top tracks information
  """
  @spec get_top_tracks() :: {:ok, [Helpers.track()]} | {:error, String.t() | any()}
  def get_top_tracks() do
    case get_data(@top_tracks_key) do
      nil ->
        get_and_cache_top_tracks()

      %{data: data} ->
        {:ok, Jason.decode!(data)}
    end
  end

  @doc """
  Get top artists information
  """
  @spec get_top_artists() :: {:ok, [Helpers.artist()]} | {:error, String.t() | any()}
  def get_top_artists() do
    case get_data(@top_artists_key) do
      nil ->
        get_and_cache_top_artists()

      %{data: data} ->
        {:ok, Jason.decode!(data)}
    end
  end

  @doc """
  Get cached now playing data
  """
  def get_cached_now_playing() do
    case get_data(@now_playing_key) do
      nil -> {:not_playing, "Nothing playing at the moment"}
      %{data: data} -> {:ok, Jason.decode!(data)}
    end
  end

  defp get_and_cache_now_playing do
    with {:ok, access_token} <- get_access_token(),
         {:ok, response} <- API.now_playing(access_token) do
      case response.status do
        200 ->
          currently_playing = Helpers.process_currently_playing(response.body["item"])

          stringified_currently_playing = Jason.encode!(currently_playing)

          {:ok, _} =
            %Schema{
              type: @now_playing_key,
              data: stringified_currently_playing,
              expire_at: Accumulator.Helpers.get_future_time(@now_playing_expire)
            }
            |> Repo.insert()

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
            %Schema{
              type: @top_tracks_key,
              data: stringified_top_tracks,
              expire_at: Accumulator.Helpers.get_future_time(@top_tracks_expire)
            }
            |> Repo.insert()

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
            %Schema{
              type: @top_artists_key,
              data: stringified_top_artists,
              expire_at: Accumulator.Helpers.get_future_time(@top_artists_expire)
            }
            |> Repo.insert()

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
    case get_data(@access_token_key) do
      nil -> refresh_access_token()
      %{data: data} -> {:ok, data}
    end
  end

  defp refresh_access_token() do
    refresh_token = get_refresh_token()
    {client_id, client_secret} = get_client_id_and_secret()

    response = API.refresh_access_token(client_id, client_secret, refresh_token)

    case response do
      {:ok, response} ->
        if response.status == 200 do
          access_token = response.body["access_token"]
          expire_seconds = response.body["expires_in"]

          {:ok, _} =
            %Schema{
              type: @access_token_key,
              data: access_token,
              expire_at: Accumulator.Helpers.get_future_time(expire_seconds)
            }
            |> Repo.insert()

          {:ok, access_token}
        else
          {:error, "Cannot refresh access token"}
        end

      error ->
        error
    end
  end

  defp get_refresh_token() do
    refresh_token_data =
      from(s in Schema, where: s.type == @refresh_token_key)
      |> Repo.one()

    case refresh_token_data do
      nil -> raise("Refresh token not present")
      %{data: data} -> data
    end
  end

  defp get_client_id_and_secret() do
    id = Application.get_env(:accumulator, :client_id)
    secret = Application.get_env(:accumulator, :client_secret)
    {id, secret}
  end

  defp get_data(type) do
    remove_expired_data()

    from(s in Schema, where: s.type == ^type)
    |> Repo.one()
  end

  defp remove_expired_data() do
    current_date_time = DateTime.utc_now() |> DateTime.truncate(:second)

    query =
      from(s in Schema,
        where: s.expire_at < ^current_date_time,
        select: s.id
      )

    Repo.delete_all(query)
  end
end
