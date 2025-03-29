defmodule Accumulator.Plants do
  alias Accumulator.Repo
  alias Accumulator.Plants.Plant

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
end
