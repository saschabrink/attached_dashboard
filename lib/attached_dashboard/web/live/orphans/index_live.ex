defmodule AttachedDashboard.Web.Live.Orphans.IndexLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Orphaned Originals",
      path: dashboard_path(socket, ~p"/orphans"),
      parent: AttachedDashboard.Web.Live.OverviewLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>Originals with no live owner reference</:subtitle>
        <:actions>
          <Button.default
            :if={MapSet.size(@selected) > 0}
            variant="danger"
            phx-click="purge_selected"
            data-confirm={"Purge #{MapSet.size(@selected)} selected group(s)?"}
          >
            Purge Selected ({MapSet.size(@selected)})
          </Button.default>
          <Button.default :if={@groups != []} variant="danger" phx-click="purge_all" data-confirm="Enqueue PurgeOrphans for all groups?">
            Purge All Orphans
          </Button.default>
        </:actions>
      </PageHeader.default>

      <Card.default class="mb-6">
        <:body>
          <p class="text-sm text-base-content/60">
            An original becomes orphaned when its owner record is deleted without going through
            Attached's purge path — for example, a direct <code class="bg-base-200 px-1 rounded">Repo.delete/1</code>
            on a user or post that had a file attached. The original remains in storage and in the
            database, but nothing references it anymore.
          </p>
          <p class="mt-2 text-sm text-base-content/60">
            This can also happen during failed transactions, bulk deletes via raw SQL, or when a
            table or field is renamed without calling <code class="bg-base-200 px-1 rounded">Attached.Ecto.Migration.rename/2,3</code>
            alongside the Ecto rename — which causes the owner reference to silently break.
          </p>
          <p class="mt-2 text-sm text-base-content/60">
            To prevent orphans, use <code class="bg-base-200 px-1 rounded">Attached.purge_later/2</code>
            before deleting the owner, or run <code class="bg-base-200 px-1 rounded">Attached.Ecto.Migration.rename</code>
            whenever you rename a table or field. The nightly <code class="bg-base-200 px-1 rounded">PurgeOrphans</code>
            worker acts as a safety net for any that slip through.
          </p>
        </:body>
      </Card.default>

      <div :if={@groups == []} class="bg-base-100 rounded-lg shadow p-8 text-center text-base-content/40">
        No orphaned originals found.
      </div>

      <Card.default :if={@groups != []}>
        <Table.default
          id="orphan-groups"
          rows={@groups}
          row_id={&group_id/1}
          selected={@selected}
          on_toggle="toggle_select"
          on_toggle_all="toggle_select_all"
          row_click={fn g -> JS.navigate(dashboard_path(@prefix, ~p"/orphans/#{g.owner_table}/#{g.owner_field}")) end}
        >
          <:col :let={g} label="Owner Table">
            <.link
              navigate={dashboard_path(@prefix, ~p"/orphans/#{g.owner_table}/#{g.owner_field}")}
              class="text-primary hover:underline font-mono text-xs"
            >
              {g.owner_table}
            </.link>
          </:col>
          <:col :let={g} label="Owner Field" class="font-mono text-xs">{g.owner_field}</:col>
          <:col :let={g} label="Count">{g.orphan_count}</:col>
          <:col :let={g} label="Total Size">{format_bytes(g.total_bytes)}</:col>
          <:action :let={g}>
            <Button.default variant="danger" phx-click={JS.push("purge_group", value: %{table: g.owner_table, field: g.owner_field})}>
              Purge
            </Button.default>
          </:action>
        </Table.default>
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(selected: MapSet.new())
     |> load_groups()
     |> PageMeta.assign_page_meta()}
  end

  @impl true
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
    visible = socket.assigns.groups |> Enum.map(&group_id/1) |> MapSet.new()

    selected =
      if MapSet.subset?(visible, socket.assigns.selected) do
        MapSet.difference(socket.assigns.selected, visible)
      else
        MapSet.union(socket.assigns.selected, visible)
      end

    {:noreply, assign(socket, selected: selected)}
  end

  def handle_event("purge_group", %{"table" => table, "field" => field}, socket) do
    Originals.purge_by_owner_group(table, field)

    {:noreply,
     socket
     |> load_groups()
     |> put_flash(:info, "Purge jobs enqueued for #{table}.#{field}.")}
  end

  def handle_event("purge_selected", _params, socket) do
    for id <- socket.assigns.selected do
      {table, field} = parse_group_id(id)
      Originals.purge_by_owner_group(table, field)
    end

    count = MapSet.size(socket.assigns.selected)

    {:noreply,
     socket
     |> assign(selected: MapSet.new())
     |> load_groups()
     |> put_flash(:info, "Purge jobs enqueued for #{count} group(s).")}
  end

  def handle_event("purge_all", _params, socket) do
    Originals.purge_orphans_later()
    {:noreply, socket |> load_groups() |> put_flash(:info, "PurgeOrphans job enqueued.")}
  end

  defp load_groups(socket) do
    assign(socket, groups: Originals.list_orphan_groups())
  end

  defp group_id(%{owner_table: table, owner_field: field}), do: "#{table}::#{field}"

  defp parse_group_id(id) do
    [table, field] = String.split(id, "::", parts: 2)
    {table, field}
  end
end
