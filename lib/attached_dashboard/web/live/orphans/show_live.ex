defmodule AttachedDashboard.Web.Live.Orphans.ShowLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals

  @per_page 25

  @impl true
  def page_meta(socket, :show),
    do: %PageMeta{
      title: "#{socket.assigns.owner_table}.#{socket.assigns.owner_field}",
      path: dashboard_path(socket, ~p"/orphans/#{socket.assigns.owner_table}/#{socket.assigns.owner_field}"),
      breadcrumb_title: socket.assigns.owner_table,
      parent: AttachedDashboard.Web.Live.Orphans.IndexLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>{@owner_table}.{@owner_field}</:subtitle>
        <:actions>
          <Button.default variant="danger" phx-click="purge_group" data-confirm={"Purge all orphans in #{@owner_table}.#{@owner_field}?"}>
            Purge Group
          </Button.default>
        </:actions>
      </PageHeader.default>

      <Card.default>
        <Table.default id="orphan-originals" rows={@originals}>
          <:col :let={original} label="Filename">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{original.id}")} class="text-primary hover:underline">
              {original.filename}
            </.link>
          </:col>
          <:col :let={original} label="Size">{format_bytes(original.byte_size)}</:col>
          <:col :let={original} label="Uploaded">{time_ago(original.inserted_at)}</:col>
          <:empty>No orphaned originals found in this group.</:empty>
        </Table.default>
        <.pagination total={@total} page={@page} per_page={@per_page} />
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(%{"owner_table" => table, "owner_field" => field}, _session, socket) do
    {:ok, assign(socket, owner_table: table, owner_field: field, page: 1)}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, socket |> load_originals() |> PageMeta.assign_page_meta()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(page: String.to_integer(page)) |> load_originals()}
  end

  def handle_event("purge_group", _params, socket) do
    Originals.purge_by_owner_group(socket.assigns.owner_table, socket.assigns.owner_field)

    {:noreply,
     socket
     |> put_flash(:info, "Purge jobs enqueued.")
     |> push_navigate(to: dashboard_path(socket, ~p"/orphans"))}
  end

  defp load_originals(socket) do
    table = socket.assigns.owner_table
    field = socket.assigns.owner_field
    page = socket.assigns.page
    offset = (page - 1) * @per_page

    assign(socket,
      originals: Originals.list_orphans(table, field, @per_page, offset),
      total: Originals.count_orphans(table, field),
      per_page: @per_page
    )
  end
end
