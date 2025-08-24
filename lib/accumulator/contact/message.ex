defmodule Accumulator.Contact.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "contact_messages" do
    field(:message, :string)
    field(:email, :string)

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:message, :email])
    |> validate_required([:message, :email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/, message: "must be a valid email")
    |> validate_length(:message, min: 1, max: 5000)
    |> validate_length(:email, max: 254)
  end
end
