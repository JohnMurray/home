defmodule Home.Repo.Migrations.AddPositionToGroceryListGroupings do
  use Ecto.Migration

  def change do
    alter table(:grocery_list_groupings) do
      add :position, :integer, null: false, default: 0
    end

    # Set initial positions based on id (existing groupings)
    execute("""
      UPDATE grocery_list_groupings
      SET position = id - (SELECT MIN(id) FROM grocery_list_groupings)
    """, "")

    create index(:grocery_list_groupings, [:position])
  end
end
