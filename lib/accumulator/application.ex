defmodule Accumulator.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = [
      dns_poll: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "aayush-battleship.internal",
          node_basename: "aayush-battleship"
        ]
      ]
    ]

    children = [
      # Start the Telemetry supervisor
      AccumulatorWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Accumulator.PubSub},
      # Shared PubSub with EventHorizon for cross-cluster messaging
      Supervisor.child_spec(
        {Phoenix.PubSub, name: EventHorizon.PubSub, adapter: Phoenix.PubSub.PG2},
        id: EventHorizon.PubSub
      ),
      # Start Finch
      {Finch, name: Accumulator.Finch},
      # Start libcluster
      {Cluster.Supervisor, [topologies, [name: Accumulator.ClusterSupervisor]]},
      # Start the Endpoint (http/https)
      AccumulatorWeb.Endpoint,
      AccumulatorWeb.Presence,
      Accumulator.Repo,
      # 5 seconds. 12 reqs/min.
      # {Accumulator.Scheduler.Spotify, interval: 5000},
      # 3_600_000: 1 hour
      {Accumulator.Scheduler.Pastes, interval: 3_600_000},
      # 43_200_000: 12 Hour
      {Accumulator.Scheduler.Plants, interval: 43_200_000},
      {Task.Supervisor, name: Accumulator.TaskRunner},
      # Analytics subscriber for EventHorizon events
      Accumulator.Analytics.Subscriber,
      # Poll subscriber for blog poll requests
      Accumulator.Poll.Subscriber
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Accumulator.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AccumulatorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
