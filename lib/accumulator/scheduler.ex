defmodule Accumulator.Scheduler.Spotify do
  use GenServer
  require Logger

  alias Accumulator.Spotify
  alias PubSubContract.Bus

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

  defp spotify_now_playing_job do
    Logger.info("Running Spotify Job")
    now_playing = Spotify.get_now_playing()

    Bus.publish(
      EventHorizon.PubSub,
      EhaPubsubMessages.Stats.Spotify.NowPlaying.new!(data: process_now_playing(now_playing))
    )
  end

  defp process_now_playing({:ok, data}), do: data
  defp process_now_playing({:not_playing, _}), do: nil
  defp process_now_playing({:error, _}), do: nil
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

defmodule Accumulator.Scheduler.Plants do
  use GenServer
  alias Accumulator.Plants

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
    notify_plant_water()
    Process.send_after(self(), :run_job, interval)
    {:noreply, interval}
  end

  defp notify_plant_water() do
    plants = Plants.get_plants_to_be_watered_today()

    if length(plants) != 0 do
      Task.Supervisor.start_child(Accumulator.TaskRunner, fn ->
        Accumulator.Mailer.send_plant_email(plants)
      end)
    end
  end
end
