defmodule AccumulatorWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :accumulator,
    pubsub_server: Accumulator.PubSub

  alias Phoenix.PubSub

  def init(_opts), do: {:ok, %{}}

  def handle_metas("user-join", _, _, state) do
    PubSub.broadcast(Accumulator.PubSub, "update:count", %{event: :main_page_user_count})
    {:ok, state}
  end

  def handle_metas("blog:" <> slug, _, _, state) do
    PubSub.broadcast(Accumulator.PubSub, "update:count", %{
      event: :blog_page_user_count,
      key: "blog:" <> slug
    })

    {:ok, state}
  end

  def handle_metas(_topic, _metas, _presences, state) do
    {:ok, state}
  end
end
