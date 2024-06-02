defmodule Accumulator.Extension do
  @moduledoc """
  Stuff for browser extension
  """
  alias Accumulator.{Repo, Extension.Bookmarks}

  # Agent stuff

  use Agent

  def start_link(_params) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_tabs(id, tabs) do
    Agent.update(__MODULE__, fn state ->
      Map.update(state, id, [], fn _ -> tabs end)
    end)
  end

  def get_tabs(id) do
    Agent.get(__MODULE__, & &1) |> Map.delete(id)
  end

  def add_bookmark(params) do
    %Bookmarks{}
    |> Bookmarks.changeset(params)
    |> Repo.insert()
  end
end
