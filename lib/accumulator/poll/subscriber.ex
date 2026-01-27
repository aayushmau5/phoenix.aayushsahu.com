defmodule Accumulator.Poll.Subscriber do
  @moduledoc """
  Subscribes to poll request and vote events from EventHorizon and responds with results.
  Listens on PollRequest and PollVote topics, publishes PollResult.
  """

  use GenServer
  require Logger

  alias Accumulator.Poll
  alias PubSubContract.Bus
  alias EhaPubsubMessages.PollRequest
  alias EhaPubsubMessages.PollVote
  alias EhaPubsubMessages.PollResult

  @pubsub EventHorizon.PubSub

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    Bus.subscribe(@pubsub, PollRequest)
    Bus.subscribe(@pubsub, PollVote)
    Logger.info("Poll subscriber started, listening on #{PollRequest.topic()} and #{PollVote.topic()}")
    {:ok, %{}}
  end

  @impl true
  def handle_info(%PollRequest{keys: keys}, state) do
    Logger.debug("Received poll request for keys: #{inspect(keys)}")
    votes = Poll.get_votes_for(keys)
    Bus.publish(@pubsub, PollResult.new!(votes: votes))
    {:noreply, state}
  end

  def handle_info(%PollVote{key: key, keys: keys}, state) do
    Logger.debug("Received poll vote for key: #{key}")
    Poll.cast_vote_for(key)
    votes = Poll.get_votes_for(keys)
    Bus.publish(@pubsub, PollResult.new!(votes: votes))
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.warning("Poll subscriber received unknown message: #{inspect(msg)}")
    {:noreply, state}
  end
end
