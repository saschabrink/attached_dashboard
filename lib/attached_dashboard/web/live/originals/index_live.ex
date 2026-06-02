defmodule AttachedDashboard.Web.Live.Originals.IndexLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  import AttachedDashboard.Web.Components.Filters

  alias Attached.Originals
  alias AttachedDashboard.Data.DashboardOriginals

  @defaults %{
    "search" => "",
    "content_type" => "",
    "storage_backend" => "",
    "owner_table" => "",
    "owner_field" => "",
    "sort_by" => "inserted_at",
    "sort_dir" => "desc",
    "page" => "1"
  }

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Originals",
      path: dashboard_path(socket, ~p"/originals"),
      parent: AttachedDashboard.Web.Live.OverviewLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    assigns = assign(assigns, fp: assigns.filter_params)

    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>{@result.total} total</:subtitle>
        <:actions>
          <Button.default :if={MapSet.size(@selected) > 0} variant="danger" phx-click="bulk_delete">
            Delete {MapSet.size(@selected)} selected
          </Button.default>
        </:actions>
      </PageHeader.default>

      <.original_filter_bar
        search={@fp["search"]}
        content_type={@fp["content_type"]}
        storage_backend={@fp["storage_backend"]}
        owner_table={@fp["owner_table"]}
        owner_field={@fp["owner_field"]}
        sort_by={@fp["sort_by"]}
        sort_dir={@fp["sort_dir"]}
        services={@services}
        owner_tables={@owner_tables}
        owner_fields={@owner_fields}
      />

      <Card.default>
        <Table.default
          id="originals"
          rows={@result.entries}
          row_id={fn {b, _} -> b.id end}
          selected={@selected}
          on_toggle="toggle_select"
          on_toggle_all="toggle_select_all"
          row_click={fn {b, _} -> JS.navigate(dashboard_path(@prefix, ~p"/originals/#{b.id}")) end}
        >
          <:col :let={{original, _}} label="Filename" class="truncate max-w-xs">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{original.id}")} class="text-primary hover:underline">
              {original.filename}
            </.link>
          </:col>
          <:col :let={{original, _}} label="Content Type">
            <div class="flex items-center gap-2 text-base-content/50">
              <MimeIcon.type type={original.content_type} class="w-4 h-4 shrink-0" />
              <span class="text-xs">{original.content_type}</span>
            </div>
          </:col>
          <:col :let={{original, _}} label="Size" class="text-base-content/50">{format_bytes(original.byte_size)}</:col>
          <:col :let={{original, _}} label="Owner Table" class="text-base-content/50 text-xs">
            {original.owner_table}
          </:col>
          <:col :let={{original, _}} label="Owner Field" class="text-base-content/50 text-xs">
            {original.owner_field}
          </:col>
          <:col :let={{original, _}} label="Backend" class="text-base-content/50">
            {original.storage_backend && List.last(String.split(original.storage_backend, "."))}
          </:col>
          <:col :let={{_, variant_count}} label="Variants" class="text-base-content/40">
            {variant_count}
          </:col>
          <:col :let={{original, _}} label="Uploaded" class="text-base-content/40">{time_ago(original.inserted_at)}</:col>
          <:empty>No originals found.</:empty>
        </Table.default>

        <.pagination
          total={@result.total}
          page={@result.page}
          per_page={@result.per_page}
        />
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      assign(socket,
        filter_params: @defaults,
        selected: MapSet.new(),
        services: Originals.list(distinct: :storage_backend, exclude_nil: true),
        owner_tables: Originals.list(distinct: :owner_table, exclude_nil: true),
        owner_fields: []
      )

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    filter_params =
      @defaults
      |> Map.merge(Map.take(params, Map.keys(@defaults)))
      |> Map.update!("page", fn v ->
        case Integer.parse(v) do
          {n, ""} when n > 0 -> Integer.to_string(n)
          _ -> "1"
        end
      end)

    {:noreply,
     socket
     |> assign(filter_params: filter_params, selected: MapSet.new())
     |> load_originals()
     |> PageMeta.assign_page_meta()}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filter_params = Map.merge(@defaults, Map.take(params, Map.keys(@defaults)))

    {:noreply,
     socket
     |> assign(filter_params: Map.put(filter_params, "page", "1"), selected: MapSet.new())
     |> load_originals()}
  end

  def handle_event("paginate", %{"page" => page}, socket) do
    filter_params = Map.put(socket.assigns.filter_params, "page", page)
    {:noreply, socket |> assign(filter_params: filter_params) |> load_originals()}
  end

  def handle_event("toggle_select", %{"id" => id}, socket) do
    selected =
      if MapSet.member?(socket.assigns.selected, id) do
        MapSet.delete(socket.assigns.selected, id)
      else
        MapSet.put(socket.assigns.selected, id)
      end

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("toggle_select_all", _params, socket) do
    visible = socket.assigns.result.entries |> Enum.map(fn {b, _} -> b.id end) |> MapSet.new()

    selected =
      if MapSet.subset?(visible, socket.assigns.selected) do
        MapSet.difference(socket.assigns.selected, visible)
      else
        MapSet.union(socket.assigns.selected, visible)
      end

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("bulk_delete", _params, socket) do
    ids = MapSet.to_list(socket.assigns.selected)
    Enum.each(ids, &Originals.purge_later/1)

    {:noreply,
     socket
     |> assign(selected: MapSet.new())
     |> load_originals()
     |> put_flash(:info, "#{length(ids)} originals queued for deletion.")}
  end

  defp load_originals(socket) do
    opts = DashboardOriginals.parse_params(socket.assigns.filter_params)

    assign(socket,
      result: DashboardOriginals.paginate(opts),
      owner_fields: owner_fields_for(opts[:owner_table])
    )
  end

  # Cascading dropdown: show all owner_fields when no table is picked,
  # otherwise only the ones seen in the selected table.
  defp owner_fields_for(""), do: Originals.list(distinct: :owner_field, exclude_nil: true)

  defp owner_fields_for(table) when is_binary(table) do
    import Ecto.Query

    Originals.list(
      distinct: :owner_field,
      exclude_nil: true,
      query: fn q -> where(q, [b], b.owner_table == ^table) end
    )
  end
end
