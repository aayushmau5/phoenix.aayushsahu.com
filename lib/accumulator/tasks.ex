defmodule Accumulator.Tasks do
  @moduledoc """
  Contains common tasks to be executed by remote nodes.
  """
  alias Accumulator.Stats
  alias Phoenix.PubSub

  def update_battleship_view_count() do
    stats = Stats.increment_blog_view_count("battleship")

    PubSub.broadcast_from(Accumulator.PubSub, self(), "update:count", %{
      event: :battleship_view_count
    })

    stats
  end
end
