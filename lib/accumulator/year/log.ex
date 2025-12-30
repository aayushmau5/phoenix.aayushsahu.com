defmodule Accumulator.Year.Log do
  use Ecto.Schema
  import Ecto.Changeset

  schema "year_logs" do
    field :text, :string
    field :logged_on, :date

    timestamps(updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:text, :logged_on])
    |> validate_required([:logged_on])
    |> unique_constraint(:logged_on)
  end
end
