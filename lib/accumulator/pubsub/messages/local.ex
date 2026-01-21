defmodule Accumulator.PubSub.Messages.Local.SiteVisit do
  @moduledoc """
  Broadcast locally when a site visit is recorded.
  """
  use PubSubContract.Message

  message do
  end

  @impl true
  def topic, do: "local:update:count"

  @impl true
  def validate(%__MODULE__{}), do: :ok
  def validate(_), do: {:error, :invalid_message}
end

defmodule Accumulator.PubSub.Messages.Local.BlogVisit do
  @moduledoc """
  Broadcast locally when a blog visit is recorded.
  """
  use PubSubContract.Message

  message do
  end

  @impl true
  def topic, do: "local:update:count"

  @impl true
  def validate(%__MODULE__{}), do: :ok
  def validate(_), do: {:error, :invalid_message}
end

defmodule Accumulator.PubSub.Messages.Local.CountUpdate do
  @moduledoc """
  Broadcast for various count updates (views, likes, presence). Local only.
  """
  use PubSubContract.Message

  message do
    field :event, :atom, required: true
    field :key, :string, default: nil
  end

  @impl true
  def topic, do: "update:count"

  @impl true
  def validate(%__MODULE__{event: event})
      when event in [
             :main_page_user_count,
             :blog_page_user_count,
             :main_page_view_count,
             :blog_page_view_count,
             :blog_like_count,
             :battleship_view_count
           ],
      do: :ok

  def validate(_), do: {:error, :invalid_event}
end
