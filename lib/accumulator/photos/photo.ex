defmodule Accumulator.Photos.Photo do
  use Ecto.Schema
  import Ecto.Changeset

  schema "photos" do
    field(:caption, :string)
    field(:place, :string)
    field(:taken_at, :utc_datetime)
    field(:width, :integer)
    field(:height, :integer)
    timestamps(type: :utc_datetime)
  end

  def changeset(photo, attrs) do
    photo
    |> cast(attrs, [:caption, :place, :taken_at, :width, :height])
    |> validate_required([:taken_at, :width, :height])
    |> validate_number(:width, greater_than: 0)
    |> validate_number(:height, greater_than: 0)
    |> validate_details()
  end

  def details_changeset(photo, attrs) do
    photo
    |> cast(attrs, [:caption, :place])
    |> validate_details()
  end

  defp validate_details(changeset) do
    changeset
    |> validate_length(:caption, max: 1000)
    |> validate_length(:place, max: 100)
  end
end
