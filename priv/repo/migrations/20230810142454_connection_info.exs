defmodule Accumulator.Repo.Migrations.ConnectionInfo do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add(:ip_address, :string)
      add(:location, :string)
      add(:device_info, :string)
    end
  end
end
