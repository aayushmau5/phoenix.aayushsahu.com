defmodule Accumulator.Pastes.Paste do
  use Ecto.Schema
  import Ecto.Changeset

  schema "pastes" do
    field(:title, :string)
    field(:content, :string)
    field(:expire_at, :utc_datetime)
    field(:time_duration, :integer, virtual: true)
    field(:time_type, :string, virtual: true)
    field(:storage_directory, :string)

    embeds_many(:files, Accumulator.Pastes.File, on_replace: :delete)

    timestamps(updated_at: false)
  end

  def changeset(paste, params \\ %{}) do
    paste
    |> cast(params, [:title, :content, :expire_at, :time_duration, :time_type, :storage_directory])
    |> validate_required([:title, :content, :time_duration, :time_type])
    |> validate_number(:time_duration, greater_than: 0)
    |> cast_embed(:files)
  end

  def update_changeset(paste, params \\ %{}) do
    paste
    |> cast(params, [:title, :content, :expire_at, :time_duration, :time_type, :storage_directory])
    |> validate_required([:title, :content, :time_duration, :time_type])
    |> validate_number(:time_duration, greater_than_or_equal_to: 0)
    |> cast_embed(:files)
  end
end
