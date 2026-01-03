defmodule Home.GroceryList.Item do
  use Ecto.Schema
  import Ecto.Changeset

  schema "grocery_list_items" do
    field :entry, :string
    field :status, :boolean, default: false
    field :position, :integer
    belongs_to :grocery_list_grouping, Home.GroceryList.Grouping

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:entry, :status, :position, :grocery_list_grouping_id])
    |> validate_required([:entry, :status, :position, :grocery_list_grouping_id])
  end
end
