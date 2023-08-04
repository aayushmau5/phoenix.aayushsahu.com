defmodule Accumulator.Pastes.File do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:type, :string)
    field(:name, :string)
    field(:access_path, :string)
    field(:storage_path, :string)
  end

  def changeset(file_entry, attrs \\ %{}) do
    file_entry
    |> cast(attrs, [:name, :access_path, :storage_path, :type], empty_values: [[], nil])
    |> validate_required([:name, :access_path, :storage_path])
  end
end
