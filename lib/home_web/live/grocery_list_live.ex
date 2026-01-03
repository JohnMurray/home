defmodule HomeWeb.GroceryListLive do
  use HomeWeb, :live_view

  alias Home.GroceryList

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="space-y-8">
        <div class="flex items-center justify-between">
          <h1 class="text-3xl font-bold">Grocery List</h1>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <%!-- Add Item Form --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Add Item</h2>
              <.form for={@item_form} id="item-form" phx-submit="add_item" phx-change="validate_item">
                <.input
                  field={@item_form[:entry]}
                  type="text"
                  label="Item"
                  placeholder="Enter item name"
                  required
                />
                <.input
                  field={@item_form[:grocery_list_grouping_id]}
                  type="select"
                  label="Grouping"
                  prompt="Select a grouping"
                  options={Enum.map(@groupings, fn g -> {g.name, g.id} end)}
                  required
                />
                <button type="submit" class="btn btn-primary mt-4">Add Item</button>
              </.form>
            </div>
          </div>

          <%!-- Add Grouping Form --%>
          <div class="card bg-base-100 shadow-xl">
            <div class="card-body">
              <h2 class="card-title">Add Grouping</h2>
              <.form for={@grouping_form} id="grouping-form" phx-submit="add_grouping" phx-change="validate_grouping">
                <.input
                  field={@grouping_form[:name]}
                  type="text"
                  label="Grouping Name"
                  placeholder="e.g., Publix, Whole Foods"
                  required
                />
                <button type="submit" class="btn btn-primary mt-4">Add Grouping</button>
              </.form>
            </div>
          </div>
        </div>

        <%!-- Grouped Items Display --%>
        <div class="space-y-6">
          <%= if Enum.empty?(@groupings) do %>
            <div class="card bg-base-100 shadow-xl">
              <div class="card-body text-center">
                <p class="text-lg text-base-content/60">No groupings yet. Create one to get started!</p>
              </div>
            </div>
          <% else %>
            <%= for grouping <- @groupings do %>
              <% items = Map.get(@items_by_grouping, grouping.id, []) %>
              <div class="card bg-base-100 shadow-xl">
                <div class="card-body">
                  <div class="flex items-center justify-between mb-4">
                    <h2 class="card-title text-2xl">{grouping.name}</h2>
                    <button
                      type="button"
                      class="btn btn-sm btn-error"
                      phx-click="delete_grouping"
                      phx-value-id={grouping.id}
                      data-confirm="Are you sure you want to delete this grouping and all its items?"
                    >
                      <.icon name="hero-trash" class="w-4 h-4" />
                      Delete
                    </button>
                  </div>

                  <%= if Enum.empty?(items) do %>
                    <p class="text-base-content/60">No items in this grouping yet.</p>
                  <% else %>
                    <div class="space-y-2">
                      <%= for item <- items do %>
                        <div
                          class={[
                            "flex items-center gap-3 p-3 rounded-lg border transition-all",
                            item.status && "bg-base-200 opacity-75",
                            !item.status && "bg-base-50 hover:bg-base-100"
                          ]}
                        >
                          <%!-- Reorder Controls --%>
                          <div class="flex flex-col gap-1">
                            <button
                              type="button"
                              class="btn btn-xs btn-ghost p-1"
                              phx-click="move_item_up"
                              phx-value-id={item.id}
                              disabled={item.position == 0}
                            >
                              <.icon name="hero-arrow-up" class="w-3 h-3" />
                            </button>
                            <button
                              type="button"
                              class="btn btn-xs btn-ghost p-1"
                              phx-click="move_item_down"
                              phx-value-id={item.id}
                            >
                              <.icon name="hero-arrow-down" class="w-3 h-3" />
                            </button>
                          </div>

                          <%!-- Checkbox --%>
                          <input
                            type="checkbox"
                            checked={item.status}
                            class="checkbox checkbox-primary"
                            phx-click="toggle_item"
                            phx-value-id={item.id}
                          />

                          <%!-- Item Entry --%>
                          <div class="flex-1">
                            <span class={[item.status && "line-through text-base-content/50", !item.status && "text-base-content"]}>
                              {item.entry}
                            </span>
                          </div>

                          <%!-- Delete Button --%>
                          <button
                            type="button"
                            class="btn btn-sm btn-ghost btn-error"
                            phx-click="delete_item"
                            phx-value-id={item.id}
                          >
                            <.icon name="hero-trash" class="w-4 h-4" />
                          </button>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    groupings = GroceryList.list_groupings()
    items_by_grouping = GroceryList.list_items_by_grouping()

    socket =
      socket
      |> assign(:groupings, groupings)
      |> assign(:items_by_grouping, items_by_grouping)
      |> assign(:item_form, to_form(%{"entry" => "", "grocery_list_grouping_id" => ""}))
      |> assign(:grouping_form, to_form(%{"name" => ""}))

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("add_item", %{"entry" => entry, "grocery_list_grouping_id" => grouping_id}, socket)
      when entry != "" and grouping_id != "" do
    case GroceryList.create_item(%{
           entry: entry,
           grocery_list_grouping_id: String.to_integer(grouping_id)
         }) do
      {:ok, _item} ->
        groupings = GroceryList.list_groupings()
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> put_flash(:info, "Item added successfully")
          |> assign(:groupings, groupings)
          |> assign(:items_by_grouping, items_by_grouping)
          |> assign(:item_form, to_form(%{"entry" => "", "grocery_list_grouping_id" => ""}))

        {:noreply, socket}

      {:error, changeset} ->
        error_message =
          changeset.errors
          |> Enum.map(fn {field, {message, _}} -> "#{field}: #{message}" end)
          |> Enum.join(", ")

        {:noreply, put_flash(socket, :error, "Failed to add item: #{error_message}")}
    end
  end

  def handle_event("add_item", _params, socket) do
    {:noreply, put_flash(socket, :error, "Please provide both entry and grouping")}
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
  def handle_event("move_item_up", %{"id" => id}, socket) do
    item = GroceryList.get_item!(id)

    case GroceryList.move_item_up(item) do
      {:ok, _item} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move item up")}
    end
  end

  @impl true
  def handle_event("move_item_down", %{"id" => id}, socket) do
    item = GroceryList.get_item!(id)

    case GroceryList.move_item_down(item) do
      {:ok, _item} ->
        items_by_grouping = GroceryList.list_items_by_grouping()

        socket =
          socket
          |> assign(:items_by_grouping, items_by_grouping)

        {:noreply, socket}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to move item down")}
    end
  end

  @impl true
  def handle_event("add_grouping", %{"name" => name}, socket) when name != "" do
    case GroceryList.create_grouping(%{"name" => name}) do
      {:ok, _grouping} ->
        groupings = GroceryList.list_groupings()

        socket =
          socket
          |> put_flash(:info, "Grouping added successfully")
          |> assign(:groupings, groupings)
          |> assign(:grouping_form, to_form(%{"name" => ""}))

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
  def handle_event("validate_item", %{"entry" => _entry, "grocery_list_grouping_id" => _grouping_id}, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("validate_grouping", %{"name" => _name}, socket) do
    {:noreply, socket}
  end
end
