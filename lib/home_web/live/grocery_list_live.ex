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
                    <p class="text-base-content/60 mb-4">No items in this grouping yet.</p>
                  <% else %>
                    <div id={"items-#{grouping.id}"} class="space-y-2 mb-4">
                      <%= for item <- items do %>
                        <div
                          id={"item-#{item.id}"}
                          draggable="true"
                          phx-hook=".DraggableItem"
                          data-item-id={item.id}
                          data-grouping-id={grouping.id}
                          class={[
                            "flex items-center gap-3 p-3 rounded-lg border transition-all cursor-move",
                            item.status && "bg-base-200 opacity-75",
                            !item.status && "bg-base-50 hover:bg-base-100"
                          ]}
                        >
                          <%!-- Drag Handle Icon --%>
                          <div class="text-base-content/40 cursor-move" data-drag-handle>
                            <.icon name="hero-bars-3" class="w-5 h-5" />
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

                  <%!-- Add Item Input at Bottom of Grouping --%>
                  <div class="border-t pt-4">
                    <.form for={to_form(%{"entry" => ""})} id={"add-item-form-#{grouping.id}"} phx-submit="add_item">
                      <input type="hidden" name="grouping_id" value={grouping.id} />
                      <div class="flex gap-2">
                        <input
                          type="text"
                          name="entry"
                          placeholder="Add new item..."
                          class="input input-bordered flex-1"
                          required
                        />
                        <button type="submit" class="btn btn-primary">
                          Add
                        </button>
                      </div>
                    </.form>
                  </div>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>

        <%!-- Add Grouping Form at Bottom --%>
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
    </Layouts.app>

    <%!-- Drag and Drop Hook --%>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".DraggableItem">
      export default {
        mounted() {
          // Make the entire item draggable, but prevent dragging when clicking interactive elements
          this.el.draggable = true;

          // Prevent dragging when clicking on interactive elements
          const interactiveElements = this.el.querySelectorAll('input, button, a');
          interactiveElements.forEach(el => {
            el.addEventListener("mousedown", (e) => {
              e.stopPropagation();
            });
            el.addEventListener("dragstart", (e) => {
              e.stopPropagation();
              e.preventDefault();
            });
          });

          this.el.addEventListener("dragstart", (e) => {
            // Don't start drag if clicking on interactive elements
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'BUTTON' || e.target.closest('button') || e.target.closest('input')) {
              e.preventDefault();
              return;
            }

            e.dataTransfer.effectAllowed = "move";
            e.dataTransfer.setData("text/plain", this.el.dataset.itemId);
            this.el.style.opacity = "0.5";
            this.el.classList.add("dragging");
          });

          this.el.addEventListener("dragend", (e) => {
            this.el.style.opacity = "";
            this.el.classList.remove("dragging");
            // Remove all drag indicators
            document.querySelectorAll('.drag-over, .drag-over-bottom').forEach(el => {
              el.classList.remove('drag-over', 'drag-over-bottom');
            });
          });

          this.el.addEventListener("dragover", (e) => {
            e.preventDefault();
            e.dataTransfer.dropEffect = "move";

            const draggedId = e.dataTransfer.getData("text/plain");
            const draggedEl = document.querySelector(`[data-item-id="${draggedId}"]`);

            if (draggedEl && draggedEl !== this.el && draggedEl.dataset.groupingId === this.el.dataset.groupingId) {
              const rect = this.el.getBoundingClientRect();
              const midpoint = rect.top + rect.height / 2;

              if (e.clientY < midpoint) {
                this.el.classList.add("drag-over");
                this.el.classList.remove("drag-over-bottom");
              } else {
                this.el.classList.add("drag-over-bottom");
                this.el.classList.remove("drag-over");
              }
            }
          });

          this.el.addEventListener("dragleave", (e) => {
            // Only remove if we're actually leaving the element
            if (!this.el.contains(e.relatedTarget)) {
              this.el.classList.remove("drag-over", "drag-over-bottom");
            }
          });

          this.el.addEventListener("drop", (e) => {
            e.preventDefault();
            this.el.classList.remove("drag-over", "drag-over-bottom");

            const draggedItemId = e.dataTransfer.getData("text/plain");
            const draggedEl = document.querySelector(`[data-item-id="${draggedItemId}"]`);

            if (draggedEl && draggedEl !== this.el) {
              // Only allow reordering within the same grouping
              if (draggedEl.dataset.groupingId === this.el.dataset.groupingId) {
                const container = this.el.parentElement;
                const allItems = Array.from(container.children).filter(child =>
                  child.dataset.itemId && child.dataset.groupingId === this.el.dataset.groupingId
                );
                const draggedIndex = allItems.indexOf(draggedEl);
                const targetIndex = allItems.indexOf(this.el);

                // Determine if we're inserting before or after the target
                const rect = this.el.getBoundingClientRect();
                const midpoint = rect.top + rect.height / 2;
                const newPosition = e.clientY < midpoint ? targetIndex : targetIndex + 1;

                // Adjust position if dragging down (we need to account for the removed item)
                const finalPosition = draggedIndex < newPosition ? newPosition - 1 : newPosition;

                // Send reorder event to server
                this.pushEvent("reorder_item", {
                  item_id: parseInt(draggedItemId),
                  new_position: Math.max(0, finalPosition)
                });
              }
            }
          });
        }
      }
    </script>
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
      |> assign(:grouping_form, to_form(%{"name" => ""}))

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
            |> put_flash(:info, "Item added successfully")
            |> assign(:groupings, groupings)
            |> assign(:items_by_grouping, items_by_grouping)

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
  def handle_event("validate_grouping", %{"name" => _name}, socket) do
    {:noreply, socket}
  end
end
