defmodule Accumulator.PubSub.Messages.Paste.Created do
  @moduledoc """
  Broadcast when a new paste is created. Local only.
  """
  use PubSubContract.Message

  message do
  end

  @impl true
  def topic, do: "paste_event"

  @impl true
  def validate(%__MODULE__{}), do: :ok
  def validate(_), do: {:error, :invalid_message}
end

defmodule Accumulator.PubSub.Messages.Paste.Deleted do
  @moduledoc """
  Broadcast when a paste is deleted. Local only.
  """

  use PubSubContract.Message

  message do
  end

  @impl true
  def topic, do: "paste_event"

  @impl true
  def validate(%__MODULE__{}), do: :ok
  def validate(_), do: {:error, :invalid_message}
end

defmodule Accumulator.PubSub.Messages.Paste.EditStatus do
  @moduledoc """
  Broadcast when paste edit presence changes. Local only.
  """
  use PubSubContract.Message

  message do
    field :paste_id, :integer, required: true
    field :count, :integer, required: true
  end

  @impl true
  def topic, do: "paste_updates"

  @impl true
  def validate(%__MODULE__{paste_id: id, count: count})
      when is_integer(id) and is_integer(count) and count >= 0,
      do: :ok

  def validate(_), do: {:error, :invalid_payload}
end

defmodule Accumulator.PubSub.Messages.Paste.Updated do
  @moduledoc """
  Broadcast when a paste is updated. Local only.
  """
  use PubSubContract.Message

  message do
    field :paste_id, :integer, required: true
  end

  @impl true
  def topic, do: "paste_updates"

  @impl true
  def validate(%__MODULE__{paste_id: id}) when is_integer(id), do: :ok
  def validate(_), do: {:error, :invalid_paste_id}
end
