defmodule HomeWeb.GroceryListLive do
  use HomeWeb, :live_view

  alias Home.GroceryList

  @impl true
  def mount(_params, _session, socket) do
    groupings = GroceryList.list_groupings()
    items_by_grouping = GroceryList.list_items_by_grouping()

    socket =
      socket
      |> assign(:groupings, groupings)
      |> assign(:items_by_grouping, items_by_grouping)
      |> assign(:grouping_form, to_form(%{"name" => ""}))
      |> assign(:editing_item_id, nil)

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_item", %{"entry" => entry} = params, socket) when entry != "" do
    grouping_id =
      case Map.get(params, "grouping_id") do
        nil -> Map.get(params, "grocery_list_grouping_id")
        id -> id
      end

    grouping_id =
      case grouping_id do
        id when is_binary(id) -> String.to_integer(id)
        id when is_integer(id) -> id
        _ -> nil
      end

    if grouping_id do
      case GroceryList.create_item(%{
             entry: entry,
             grocery_list_grouping_id: grouping_id
           }) do
        {:ok, _item} ->
          groupings = GroceryList.list_groupings()
          items_by_grouping = GroceryList.list_items_by_grouping()

          socket =
            socket
            |> assign(:groupings, groupings)
            |> assign(:items_by_grouping, items_by_grouping)
            |> push_event("clear_form", %{})

          {:noreply, socket}

        {:error, changeset} ->
          error_message =
            changeset.errors
            |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
            |> Enum.join(", ")

          {:noreply, put_flash(socket, :error, "Failed to add item: #{error_message}")}
      end
    else
      {:noreply, put_flash(socket, :error, "Please provide a grouping")}
    end
  end

  def handle_event("add_item", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please provide an item name")}
  end

  @impl true
  def handle_event("toggle_item", %{"id" => id}, socket) do
    item = GroceryList.get_item!(id)

    case GroceryList.toggle_item_status(item) do
      {:ok, _item} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to toggle item status")}
    end
  end

  @impl true
  def handle_event("delete_item", %{"id" => id}, socket) do
    item = GroceryList.get_item!(id)

    case GroceryList.delete_item(item) do
      {:ok, _} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> put_flash(:info, "Item deleted successfully")
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete item")}
    end
  end

  @impl true
  def handle_event("reorder_item", %{"item_id" => item_id, "new_position" => new_position}, socket) do
    item = GroceryList.get_item!(item_id)

    case GroceryList.reorder_item(item, new_position) do
      {:ok, _item} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to reorder item")}
    end
  end

  @impl true
  def handle_event("start_edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, :editing_item_id, String.to_integer(id))}
  end

  @impl true
  def handle_event("cancel_edit", _params, socket) do
    {:noreply, assign(socket, :editing_item_id, nil)}
  end

  @impl true
  def handle_event("keydown", %{"key" => "Escape"}, socket) do
    {:noreply, assign(socket, :editing_item_id, nil)}
  end

  @impl true
  def handle_event("update_item", %{"item_id" => item_id, "entry" => entry}, socket) do
    item = GroceryList.get_item!(item_id)

    case GroceryList.update_item(item, %{entry: entry}) do
      {:ok, _item} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> put_flash(:info, "Item updated successfully")
          |> assign(:items_by_grouping, items_by_grouping)
          |> assign(:editing_item_id, nil)

        {:noreply, socket}

      {:error, changeset} ->
        error_message =
          changeset.errors
          |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, "Failed to update item: #{error_message}")}
    end
  end

  @impl true
  def handle_event("add_grouping", %{"name" => name}, socket) when name != "" do
    case GroceryList.create_grouping(%{name: name}) do
      {:ok, _grouping} ->
        groupings = GroceryList.list_groupings()

        socket =
          socket
          |> assign(:groupings, groupings)
          |> assign(:grouping_form, to_form(%{"name" => ""}))
          |> push_event("clear_form", %{})

        {:noreply, socket}

      {:error, changeset} ->
        error_message =
          if changeset.errors[:name] do
            "Grouping name already exists"
          else
            "Failed to add grouping"
          end

        {:noreply, put_flash(socket, :error, error_message)}
    end
  end

  def handle_event("add_grouping", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please provide a grouping name")}
  end

  @impl true
  def handle_event("move_grouping_up", %{"id" => id}, socket) do
    grouping = GroceryList.get_grouping!(id)

    case GroceryList.move_grouping_up(grouping) do
      {:ok, _grouping} ->
        groupings = GroceryList.list_groupings()

        socket =
          socket
          |> assign(:groupings, groupings)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move grouping up")}
    end
  end

  @impl true
  def handle_event("move_grouping_down", %{"id" => id}, socket) do
    grouping = GroceryList.get_grouping!(id)

    case GroceryList.move_grouping_down(grouping) do
      {:ok, _grouping} ->
        groupings = GroceryList.list_groupings()

        socket =
          socket
          |> assign(:groupings, groupings)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move grouping down")}
    end
  end

  @impl true
  def handle_event("delete_grouping", %{"id" => id}, socket) do
    grouping = GroceryList.get_grouping!(id)

    case GroceryList.delete_grouping(grouping) do
      {:ok, _} ->
        groupings = GroceryList.list_groupings()
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> put_flash(:info, "Grouping deleted successfully")
          |> assign(:groupings, groupings)
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to delete grouping")}
    end
  end


  @impl true
  def handle_event("validate_grouping", %{"name" => _name}, socket) do
    {:noreply, socket}
  end
end
