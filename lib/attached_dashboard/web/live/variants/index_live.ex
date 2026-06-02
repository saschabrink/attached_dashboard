defmodule AttachedDashboard.Web.Live.Variants.IndexLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Variants

  @per_page 25

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Variants",
      path: dashboard_path(socket, ~p"/variants"),
      parent: AttachedDashboard.Web.Live.OverviewLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>{@result.total} cached derivations</:subtitle>
      </PageHeader.default>

      <Card.default class="mb-6">
        <:body>
          <p class="text-sm text-base-content/60">
            Variants are cached derivations of
            <.link
              navigate={dashboard_path(@prefix, ~p"/originals")}
              class="text-primary hover:underline"
            >
              originals
            </.link>
            — thumbnails, resized images, format conversions. Each variant is identified by its
            parent original and a transform digest; stale digests are reaped automatically.
          </p>
        </:body>
      </Card.default>

      <Card.default>
        <Table.default
          id="variants"
          rows={@result.entries}
          row_click={fn v -> JS.navigate(dashboard_path(@prefix, ~p"/originals/#{v.original.id}/variants/#{v.id}")) end}
        >
          <:col :let={variant} label="Name" class="truncate max-w-xs">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{variant.original.id}/variants/#{variant.id}")} class="text-primary hover:underline">
              {variant.name}
            </.link>
          </:col>
          <:col :let={variant} label="Original">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{variant.original.id}")} class="text-primary hover:underline">
              {variant.original.filename}
            </.link>
          </:col>
          <:col :let={variant} label="Content Type">
            <div class="flex items-center gap-2 text-base-content/50">
              <MimeIcon.type type={variant.content_type} class="w-4 h-4 shrink-0" />
              <span class="text-xs">{variant.content_type}</span>
            </div>
          </:col>
          <:col :let={variant} label="Size" class="text-base-content/50">{format_bytes(variant.byte_size)}</:col>
          <:col :let={variant} label="Digest" class="font-mono text-xs text-base-content/40">
            {String.slice(variant.transform_digest, 0, 12)}…
          </:col>
          <:col :let={variant} label="Created" class="text-base-content/40">{time_ago(variant.inserted_at)}</:col>
          <:empty>No variants found.</:empty>
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
    {:ok, assign(socket, page: 1)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    page =
      case Integer.parse(params["page"] || "1") do
        {n, ""} when n > 0 -> n
        _ -> 1
      end

    {:noreply,
     socket
     |> assign(page: page)
     |> load_variants()
     |> PageMeta.assign_page_meta()}
  end

  @impl true
  def handle_event("paginate", %{"page" => page}, socket) do
    {:noreply, socket |> assign(page: String.to_integer(page)) |> load_variants()}
  end

  defp load_variants(socket) do
    assign(socket,
      result:
        Variants.paginate(
          preload: :original,
          order_by: [desc: :inserted_at],
          page: socket.assigns.page,
          per_page: @per_page
        )
    )
  end
end
