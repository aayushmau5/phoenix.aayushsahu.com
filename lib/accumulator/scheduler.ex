defmodule Accumulator.Scheduler.Spotify do
  use GenServer
  require Logger

  alias Accumulator.Spotify
  alias AccumulatorWeb.Presence
  alias Phoenix.PubSub

  def start_link(args) do
    interval = Keyword.get(args, :interval)
    GenServer.start_link(__MODULE__, interval)
  end

  @impl true
  def init(interval) do
    Process.send_after(self(), :run_job, interval)
    {:ok, interval}
  end

  @impl true
  def handle_info(:run_job, interval) do
    spotify_now_playing_job()
    Process.send_after(self(), :run_job, interval)
    {:noreply, interval}
  end

  def spotify_now_playing_job do
    users_connected = Presence.list("spotify-join") |> map_size()

    if users_connected != 0 do
      Logger.info("Running Spotify Job")
      now_playing = Spotify.get_now_playing()

      PubSub.broadcast_from(Accumulator.PubSub, self(), "spotify:now_playing_update", %{
        event: :spotify_now_playing,
        data: now_playing
      })
    end
  end
end

defmodule Accumulator.Scheduler.Pastes do
  use GenServer
  require Logger

  alias Accumulator.Pastes

  def start_link(args) do
    interval = Keyword.get(args, :interval)
    GenServer.start_link(__MODULE__, interval)
  end

  @impl true
  def init(interval) do
    Process.send_after(self(), :run_job, interval)
    {:ok, interval}
  end

  @impl true
  def handle_info(:run_job, interval) do
    cleanup_expired_pastes()
    Process.send_after(self(), :run_job, interval)
    {:noreply, interval}
  end

  def cleanup_expired_pastes do
    Logger.info("Cleaning up expired jobs")
    Pastes.cleanup_expired_pastes()
  end
end
