defmodule Home.GroceryList.Grouping do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grocery_list_groupings" do
    field :name, :string
    has_many :items, Home.GroceryList.Item, foreign_key: :grocery_list_grouping_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(grouping, attrs) do
    grouping
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end
end
