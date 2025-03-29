defmodule Accumulator.Plants.Plant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "plants" do
    field(:name, :string)
    field(:info, :string)
    field(:image, :string)
    field(:care, :string)
    field(:watering_frequency, :string)
    field(:watered_on, :date)
    field(:next_water_on, :date)
    field(:potting_notes, :string)
    timestamps()
  end

  @doc false
  def changeset(plant, attrs) do
    plant
    |> cast(attrs, [
      :name,
      :image,
      :info,
      :care,
      :watering_frequency,
      :watered_on,
      :next_water_on,
      :potting_notes
    ])
    |> validate_required([:name, :image, :info, :care, :watering_frequency])
  end
end
