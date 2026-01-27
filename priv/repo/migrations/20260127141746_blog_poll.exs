defmodule Accumulator.Repo.Migrations.BlogPoll do
  use Ecto.Migration

  def change do
    create table(:blog_polls) do
      add :key, :text
      add :vote, :integer

      timestamps(inserted_at: false, updated_at: false)
    end
  end
end
