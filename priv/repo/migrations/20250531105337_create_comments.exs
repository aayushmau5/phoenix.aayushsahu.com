defmodule Accumulator.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :content, :text, null: false
      add :author, :string
      add :blog_slug, :string, null: false
      add :parent_id, references(:comments, on_delete: :delete_all), null: true

      timestamps()
    end

    create index(:comments, [:blog_slug])
    create index(:comments, [:parent_id])
  end
end
