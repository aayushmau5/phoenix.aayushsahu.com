defmodule Accumulator.Repo.Migrations.CreateContactMessages do
  use Ecto.Migration

  def change do
    create table(:contact_messages, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:message, :text, null: false)
      add(:email, :string, null: false)

      timestamps()
    end

    create(index(:contact_messages, [:inserted_at]))
    create(index(:contact_messages, [:email]))
  end
end
