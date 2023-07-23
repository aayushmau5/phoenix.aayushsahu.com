defmodule Accumulator.Pastes.Paste do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pastes" do
    field(:title, :string)
    field(:content, :string)
    field(:expire_at, :utc_datetime)
    field(:time_duration, :integer, virtual: true)
    field(:time_type, :string, virtual: true)

    timestamps(updated_at: false)
  end

  def changeset(paste, params \\ %{}) do
    # TODO: validate expire_at greater than current time
    paste
    |> cast(params, [:title, :content, :expire_at, :time_duration, :time_type])
    |> validate_required([:title, :content, :time_duration, :time_type])
    |> validate_number(:time_duration, greater_than: 0)
  end
end
