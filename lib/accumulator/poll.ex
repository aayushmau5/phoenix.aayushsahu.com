defmodule Accumulator.Poll.Schema do
  use Ecto.Schema
  import Ecto.Changeset

  schema "blog_polls" do
    field(:key, :string)
    field(:vote, :integer)
    timestamps(inserted_at: false, updated_at: false)
  end

  def changeset(poll, params \\ %{}) do
    poll |> cast(params, [:key, :vote]) |> validate_required([:key])
  end
end

defmodule Accumulator.Poll do
  import Ecto.Query
  alias Accumulator.Poll.Schema
  alias Accumulator.Repo

  def create_poll_for(key) do
    %Schema{} |> Schema.changeset(%{key: key, vote: 0}) |> Repo.insert()
  end

  def cast_vote_for(key) do
    Schema
    |> where([p], p.key == ^key)
    |> Repo.update_all(inc: [vote: 1])
  end

  def get_votes_for(keys) do
    Schema
    |> where([p], p.key in ^keys)
    |> select([p], {p.key, p.vote})
    |> Repo.all()
    |> Map.new()
  end
end
