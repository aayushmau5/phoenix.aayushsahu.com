defmodule :"Elixir.Accumulator.Repo.Migrations.Extension-bookmarks" do
  use Ecto.Migration

  def change do
    create table(:extension_bookmarks) do
      add(:url, :text)
      add(:title, :text)
      add(:browser_id, :string)
      timestamps(updated_at: false)
    end
  end
end
