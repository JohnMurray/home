defmodule Home.GroceryList do
  @moduledoc """
  The GroceryList context.
  """

  import Ecto.Query, warn: false
  alias Home.Repo
  alias Home.GroceryList.{Grouping, Item}

  ## Groupings

  def list_groupings do
    Repo.all(Grouping)
  end

  def get_grouping!(id), do: Repo.get!(Grouping, id)

  def create_grouping(attrs \\ %{}) do
    %Grouping{}
    |> Grouping.changeset(attrs)
    |> Repo.insert()
  end

  def update_grouping(%Grouping{} = grouping, attrs) do
    grouping
    |> Grouping.changeset(attrs)
    |> Repo.update()
  end

  def delete_grouping(%Grouping{} = grouping) do
    Repo.delete(grouping)
  end

  ## Items

  def list_items do
    Repo.all(
      from i in Item,
        order_by: [asc: i.position],
        preload: :grocery_list_grouping
    )
  end

  def list_items_by_grouping do
    items =
      Repo.all(
        from i in Item,
          order_by: [asc: i.grocery_list_grouping_id, asc: i.position],
          preload: :grocery_list_grouping
      )

    Enum.group_by(items, & &1.grocery_list_grouping_id)
  end

  def get_item!(id), do: Repo.get!(Item, id) |> Repo.preload(:grocery_list_grouping)

  def create_item(attrs \\ %{}) do
    # Handle both string and atom keys
    grouping_id = Map.get(attrs, :grocery_list_grouping_id) ||
                   (case Map.get(attrs, "grocery_list_grouping_id") do
                     nil -> nil
                     id when is_binary(id) -> String.to_integer(id)
                     id -> id
                   end)

    entry = Map.get(attrs, :entry) || Map.get(attrs, "entry")
    status = Map.get(attrs, :status) || Map.get(attrs, "status", false)

    position =
      if grouping_id do
        max_position =
          Repo.one(
            from i in Item,
              where: i.grocery_list_grouping_id == ^grouping_id,
              select: max(i.position)
          ) || 0

        max_position + 1
      else
        0
      end

    attrs_with_position = %{
      entry: entry,
      grocery_list_grouping_id: grouping_id,
      position: position,
      status: status
    }

    %Item{}
    |> Item.changeset(attrs_with_position)
    |> Repo.insert()
  end

  def update_item(%Item{} = item, attrs) do
    item
    |> Item.changeset(attrs)
    |> Repo.update()
  end

  def delete_item(%Item{} = item) do
    grouping_id = item.grocery_list_grouping_id
    position = item.position

    Repo.transaction(fn ->
      Repo.delete(item)

      # Reorder remaining items in the same grouping
      from(i in Item,
        where:
          i.grocery_list_grouping_id == ^grouping_id and
            i.position > ^position,
        update: [set: [position: fragment("position - 1")]]
      )
      |> Repo.update_all([])
    end)
  end

  def toggle_item_status(%Item{} = item) do
    update_item(item, %{status: !item.status})
  end

  def reorder_item(%Item{} = item, new_position) when is_integer(new_position) do
    grouping_id = item.grocery_list_grouping_id
    old_position = item.position

    if new_position == old_position do
      {:ok, item}
    else
      Repo.transaction(fn ->
        if new_position > old_position do
          # Moving down: shift items between old and new position up
          from(i in Item,
            where:
              i.grocery_list_grouping_id == ^grouping_id and
                i.position > ^old_position and
                i.position <= ^new_position,
            update: [set: [position: fragment("position - 1")]]
          )
          |> Repo.update_all([])
        else
          # Moving up: shift items between new and old position down
          from(i in Item,
            where:
              i.grocery_list_grouping_id == ^grouping_id and
                i.position >= ^new_position and
                i.position < ^old_position,
            update: [set: [position: fragment("position + 1")]]
          )
          |> Repo.update_all([])
        end

        case update_item(item, %{position: new_position}) do
          {:ok, updated_item} -> updated_item
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end)
    end
  end

  def move_item_up(%Item{} = item) do
    if item.position > 0 do
      reorder_item(item, item.position - 1)
    else
      {:ok, item}
    end
  end

  def move_item_down(%Item{} = item) do
    grouping_id = item.grocery_list_grouping_id

    max_position =
      Repo.one(
        from i in Item,
          where: i.grocery_list_grouping_id == ^grouping_id,
          select: max(i.position)
      ) || 0

    if item.position < max_position do
      reorder_item(item, item.position + 1)
    else
      {:ok, item}
    end
  end
end
