defmodule Accumulator.Repo.Migrations.NotesSearch do
  use Ecto.Migration

  def change do
    execute("""
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    """)

    execute("""
      CREATE INDEX notes_searchable_idx ON notes USING GIN (text gin_trgm_ops);
    """)
  end
end
