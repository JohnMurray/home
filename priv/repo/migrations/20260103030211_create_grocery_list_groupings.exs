defmodule Home.Repo.Migrations.CreateGroceryListGroupings do
  use Ecto.Migration

  def change do
    create table(:grocery_list_groupings) do
      add :name, :string, null: false
      timestamps(type: :utc_datetime)
    end

    create unique_index(:grocery_list_groupings, [:name])
  end
end
