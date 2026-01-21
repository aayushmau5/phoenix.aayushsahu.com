defmodule Accumulator.PubSub.Messages.Notes.Changed do
  @moduledoc """
  Broadcast when a note or workspace is created, updated, or deleted. Local only.
  """
  use PubSubContract.Message

  message do
    field :type, :atom, required: true
    field :workspace_id, :any, required: true
  end

  @impl true
  def topic, do: "notes-pubsub-event"

  @impl true
  def validate(%__MODULE__{type: type, workspace_id: workspace_id})
      when type in [:new_note, :update_note, :delete_note, :new_workspace, :update_workspace, :delete_workspace] and
             not is_nil(workspace_id),
      do: :ok

  def validate(_), do: {:error, :invalid_payload}
end
