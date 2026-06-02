defmodule AttachedDashboard.Web.Live.OverviewLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals
  alias Attached.Originals.Stats
  alias Attached.Variants

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Attached Dashboard",
      breadcrumb_title: "Overview",
      path: dashboard_path(socket, ~p"/")
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta} breadcrumbs={false} />

      <div class="grid grid-cols-2 sm:grid-cols-4 gap-4 mb-8">
        <.stat_card label="Originals" value={@original_stats.record_count} navigate={dashboard_path(@prefix, ~p"/originals")} />
        <.stat_card label="Variants" value={@variant_count} navigate={dashboard_path(@prefix, ~p"/variants")} />
        <.stat_card label="Orphaned" value={@orphan_count} navigate={dashboard_path(@prefix, ~p"/orphans")} />
        <.stat_card label="Total Size" value={format_bytes(@original_stats.total_bytes)} />
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div class="bg-base-100 rounded-lg shadow p-5">
          <h2 class="text-sm font-semibold text-base-content/70 mb-4">Content Type Distribution</h2>
          <ul class="space-y-3">
            <li :for={row <- @by_content_type}>
              <div class="flex justify-between text-sm mb-1">
                <span class="text-base-content/60">{row.type || "unknown"}</span>
                <span class="text-base-content/40">{row.record_count} files</span>
              </div>
              <div class="w-full h-2 bg-base-200 rounded-full overflow-hidden">
                <div
                  class="h-full rounded-full bar-gradient"
                  style={"width: #{Float.round(row.record_count / @content_type_total * 100, 1)}%"}
                />
              </div>
            </li>
          </ul>
        </div>

        <div class="bg-base-100 rounded-lg shadow p-5">
          <h2 class="text-sm font-semibold text-base-content/70 mb-4">Storage Usage</h2>
          <div class="bg-primary/10 rounded-lg p-4 py-2 text-center mb-4">
            <p class="text-xs text-base-content/50 mb-1">Total Storage Used</p>
            <p class="text-2xl font-bold text-primary">{format_bytes(@original_stats.total_bytes)}</p>
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div class="text-center">
              <p class="text-xs text-base-content/50 mb-1">Average File Size</p>
              <p class="text-base font-semibold text-base-content">
                {format_bytes(avg_bytes(@by_storage_backend, @original_stats))}
              </p>
            </div>
            <div class="text-center">
              <p class="text-xs text-base-content/50 mb-1">Largest File</p>
              <p class="text-base font-semibold text-base-content">
                {format_bytes(max_bytes(@by_storage_backend))}
              </p>
            </div>
          </div>
        </div>
      </div>

      <Card.default>
        <:title>Recent Uploads</:title>
        <Table.default id="recent-uploads" rows={@recent_originals}>
          <:col :let={original} label="Filename">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{original.id}")} class="text-primary hover:underline">
              {original.filename}
            </.link>
          </:col>
          <:col :let={original} label="Type">
            <div class="flex items-center gap-2 text-base-content/50">
              <MimeIcon.type type={original.content_type} class="w-4 h-4 shrink-0" />
              <span class="text-xs">{original.content_type}</span>
            </div>
          </:col>
          <:col :let={original} label="Size">{format_bytes(original.byte_size)}</:col>
          <:col :let={original} label="Uploaded">{time_ago(original.inserted_at)}</:col>
        </Table.default>
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    by_content_type = Stats.by_content_type()

    {:ok,
     socket
     |> assign(
       original_stats: Stats.overview(),
       by_content_type: by_content_type,
       content_type_total: Enum.sum(Enum.map(by_content_type, & &1.record_count)),
       by_storage_backend: Stats.by_storage_backend(),
       orphan_count: Originals.count_orphans(),
       variant_count: Variants.count(),
       recent_originals: Originals.list(order_by: [desc: :inserted_at], limit: 8)
     )
     |> PageMeta.assign_page_meta()}
  end

  defp avg_bytes([], _), do: 0

  defp avg_bytes(_by_storage_backend, %{total_bytes: total, record_count: count})
       when count > 0,
       do: trunc(total / count)

  defp avg_bytes(_, _), do: 0

  defp max_bytes([]), do: 0
  defp max_bytes(by_storage_backend), do: by_storage_backend |> Enum.map(& &1.max_bytes) |> Enum.max()
end
