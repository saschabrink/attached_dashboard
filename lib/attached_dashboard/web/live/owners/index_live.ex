defmodule AttachedDashboard.Web.Live.Owners.IndexLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals.Stats

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Owners",
      path: dashboard_path(socket, ~p"/owners"),
      parent: AttachedDashboard.Web.Live.OverviewLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>Schemas and fields that own attached originals</:subtitle>
      </PageHeader.default>

      <Card.default class="mb-6">
        <:body>
          <p class="text-sm text-base-content/60">
            Each row groups originals by their <code class="bg-base-200 px-1 rounded">owner_table</code>
            and <code class="bg-base-200 px-1 rounded">owner_field</code>
            — the schema and column
            that references them. Use this view to understand where attached files live in your
            application, then click through to filter originals by that group.
          </p>
        </:body>
      </Card.default>

      <div :if={@groups == []} class="bg-base-100 rounded-lg shadow p-8 text-center text-base-content/40">
        No owners yet — nothing has uploaded an original.
      </div>

      <Card.default :if={@groups != []}>
        <Table.default
          id="owner-groups"
          rows={@groups}
          row_click={fn g -> JS.navigate(originals_for(@prefix, g)) end}
        >
          <:col :let={g} label="Owner Table" class="font-mono text-xs">
            <.link navigate={originals_for(@prefix, g)} class="text-primary hover:underline">
              {g.owner_table}
            </.link>
          </:col>
          <:col :let={g} label="Owner Field" class="font-mono text-xs">{g.owner_field}</:col>
          <:col :let={g} label="Originals">{g.original_count}</:col>
          <:col :let={g} label="Total Size">{format_bytes(g.total_bytes)}</:col>
          <:action :let={g}>
            <Button.default variant="secondary" navigate={originals_for(@prefix, g)}>Browse</Button.default>
          </:action>
        </Table.default>
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, groups: Stats.by_owner_group())}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, PageMeta.assign_page_meta(socket)}
  end

  defp originals_for(prefix, %{owner_table: table, owner_field: field}) do
    dashboard_path(prefix, ~p"/originals?owner_table=#{table}&owner_field=#{field}")
  end
end
