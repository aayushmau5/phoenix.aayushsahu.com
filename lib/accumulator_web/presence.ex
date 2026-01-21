defmodule AccumulatorWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :accumulator,
    pubsub_server: Accumulator.PubSub

  alias PubSubContract.Bus
  alias Accumulator.PubSub.Topics
  alias Accumulator.PubSub.Messages.Local.CountUpdate
  alias Accumulator.PubSub.Messages.Paste.EditStatus

  def init(_opts), do: {:ok, %{}}

  def handle_metas("user-join", _, _, state) do
    Bus.publish(Accumulator.PubSub, CountUpdate.new!(event: :main_page_user_count))
    {:ok, state}
  end

  def handle_metas("blog:" <> id, _, _, state) do
    Bus.publish(Accumulator.PubSub, CountUpdate.new!(event: :blog_page_user_count, key: "blog:" <> id))
    {:ok, state}
  end

  def handle_metas("paste_edit:" <> id, _metas, presences, state) do
    paste_id = String.to_integer(id)
    topic = Topics.paste_updates(paste_id: paste_id)
    Bus.publish(Accumulator.PubSub, EditStatus.new!(paste_id: paste_id, count: map_size(presences)), topic: topic)
    {:ok, state}
  end

  def handle_metas(_topic, _metas, _presences, state) do
    {:ok, state}
  end
end
