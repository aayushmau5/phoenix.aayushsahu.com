defmodule Accumulator.Plants do
  import Ecto.Query
  alias Accumulator.Repo
  alias Accumulator.Plants.{Plant, WateringFreq}

  def list_plants do
    Repo.all(Plant)
  end

  def get_plant!(id), do: Repo.get!(Plant, id)

  def create_plant(attrs \\ %{}) do
    %Plant{}
    |> Plant.changeset(attrs)
    |> Repo.insert()
  end

  def update_plant(%Plant{} = plant, attrs) do
    plant
    |> Plant.changeset(attrs)
    |> Repo.update()
  end

  def delete_plant(%Plant{} = plant) do
    Repo.delete(plant)
  end

  def update_next_water_date(%Plant{} = plant) do
    next_water_on = WateringFreq.convert_to_date(plant.watered_on, plant.watering_frequency)
    update_plant(plant, %{next_water_on: next_water_on})
  end

  def get_plants_to_be_watered_today() do
    today = Date.utc_today()

    from(p in Plant, where: fragment("?::date", p.next_water_on) == ^today)
    |> Repo.all()
  end
end
