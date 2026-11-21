defmodule Accumulator.Repo.Migrations.AddLastUsedAtToUsersTokens do
  use Ecto.Migration

  def up do
    alter table(:users_tokens) do
      add(:last_used_at, :naive_datetime,
        null: false,
        default: fragment("(now() at time zone 'utc')")
      )
    end

    execute("UPDATE users_tokens SET last_used_at = inserted_at")
  end

  def down do
    alter table(:users_tokens) do
      remove(:last_used_at)
    end
  end
end
