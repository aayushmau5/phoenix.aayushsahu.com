defmodule Accumulator.Tasks do
  @moduledoc """
  Contains common tasks to be executed by remote nodes.
  """
  alias Accumulator.Stats
  alias PubSubContract.Bus
  alias Accumulator.PubSub.Messages.Local.CountUpdate

  def update_battleship_view_count() do
    stats = Stats.increment_blog_view_count("battleship")

    Bus.publish_from(Accumulator.PubSub, self(), CountUpdate.new!(event: :battleship_view_count))

    stats
  end
end
