defmodule Accumulator.PubSub.Topics do
  @moduledoc """
  Local topic patterns for Accumulator's internal PubSub.
  For shared topics, use `EhaPubsubMessages.Topics`.
  """
  use PubSubContract.Topics

  # Dynamic topics (local only)
  topic(:paste_updates, "paste_updates:{paste_id}")

  # Static topics (local only)
  def spotify_now_playing, do: "spotify:now_playing_update"
  def paste_event, do: "paste_event"
  def notes_event, do: "notes-pubsub-event"
  def local_update_count, do: "local:update:count"
  def update_count, do: "update:count"
end
