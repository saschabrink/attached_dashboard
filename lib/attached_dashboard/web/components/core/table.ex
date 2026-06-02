defmodule AttachedDashboard.Web.Components.Core.Table do
  @moduledoc false

  use Phoenix.Component

  alias Phoenix.LiveView.JS

  @doc """
  Renders a table with generic styling.

  ## Attrs

  - `table_class` — applied to the `<table>` element. Defaults to `"table table-zebra"`.
  - `row_class` — 1-arity function receiving the row, returns a CSS class string for the `<tr>`.

  ## Selection

  Pass `selected` (a `MapSet` of row IDs) to enable a checkbox column on the left.
  Requires `row_id` to identify rows. `on_toggle` fires per-row with `phx-value-id`,
  `on_toggle_all` fires when the header checkbox is clicked (the handler must know
  which rows are on the current page).

      <Table.default
        id="orphan-groups"
        rows={@groups}
        selected={@selected}
        on_toggle="toggle_select"
        on_toggle_all="toggle_select_all"
        row_id={&"\#{&1.owner_table}.\#{&1.owner_field}"}
      >
        ...
      </Table.default>

  ## Col slot attrs

  - `label` — header cell text
  - `class` — applied to `<td>` body cells only

  ## Examples

      <Table.default id="originals" rows={@originals}>
        <:col :let={b} label="Filename">{b.filename}</:col>
        <:col :let={b} label="Size">{format_bytes(b.byte_size)}</:col>
      </Table.default>
  """
  attr :id, :string, required: true
  attr :rows, :list, required: true
  attr :table_class, :string, default: "table table-zebra"
  attr :row_id, :any, default: nil
  attr :row_click, :any, default: nil
  attr :row_item, :any, default: &Function.identity/1
  attr :row_class, :any, default: nil
  attr :selected, :any, default: nil
  attr :on_toggle, :string, default: nil
  attr :on_toggle_all, :string, default: nil

  slot :col, required: true do
    attr :label, :string
    attr :class, :string
  end

  slot :action
  slot :empty

  def default(assigns) do
    if assigns.selected && is_nil(assigns.row_id) do
      raise ArgumentError, "Table with :selected requires :row_id to identify rows"
    end

    assigns =
      with %{rows: %Phoenix.LiveView.LiveStream{}} <- assigns do
        assign(assigns, row_id: assigns.row_id || fn {id, _item} -> id end)
      end

    ~H"""
    <div class="overflow-x-auto">
      <table class={@table_class}>
        <thead>
          <tr>
            <th :if={@selected} class="w-0">
              <input
                type="checkbox"
                class="h-4 w-4 accent-primary cursor-pointer"
                disabled={@rows == []}
                checked={all_on_page_selected?(@rows, @selected, @row_id)}
                phx-click={@on_toggle_all && JS.push(@on_toggle_all)}
              />
            </th>
            <th :for={col <- @col}>{col[:label]}</th>
            <th :if={@action != []}><span class="sr-only">Actions</span></th>
          </tr>
        </thead>
        <tbody id={@id} phx-update={is_struct(@rows, Phoenix.LiveView.LiveStream) && "stream"}>
          <tr :if={@rows == []}>
            <td
              colspan={length(@col) + if(@action != [], do: 1, else: 0) + if(@selected, do: 1, else: 0)}
              class="px-4 py-8 text-center text-base-content/40"
            >
              {if @empty != [], do: render_slot(@empty), else: "No records found."}
            </td>
          </tr>
          <tr
            :for={row <- @rows}
            id={@row_id && @row_id.(row)}
            class={@row_class && @row_class.(row)}
          >
            <td :if={@selected} class="w-0">
              <input
                type="checkbox"
                class="h-4 w-4 accent-primary cursor-pointer"
                checked={MapSet.member?(@selected, @row_id.(row))}
                phx-click={@on_toggle && JS.push(@on_toggle, value: %{id: @row_id.(row)})}
              />
            </td>
            <td
              :for={col <- @col}
              phx-click={@row_click && @row_click.(row)}
              class={[@row_click && "hover:cursor-pointer", col[:class]]}
            >
              {render_slot(col, @row_item.(row))}
            </td>
            <td :if={@action != []} class="w-0">
              <div class="flex gap-4 justify-end">
                <%= for action <- @action do %>
                  {render_slot(action, @row_item.(row))}
                <% end %>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  defp all_on_page_selected?([], _selected, _row_id), do: false

  defp all_on_page_selected?(rows, selected, row_id)
       when is_list(rows) and is_function(row_id, 1) do
    Enum.all?(rows, fn row -> MapSet.member?(selected, row_id.(row)) end)
  end

  defp all_on_page_selected?(_, _, _), do: false
end
