defmodule Home.Repo.Migrations.CreateGroceryListItems do
  use Ecto.Migration

  def change do
    create table(:grocery_list_items) do
      add :entry, :string, null: false
      add :status, :boolean, default: false, null: false
      add :position, :integer, null: false
      add :grocery_list_grouping_id, references(:grocery_list_groupings, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime)
    end

    create index(:grocery_list_items, [:grocery_list_grouping_id, :position])
  end
end
