defmodule AttachedDashboard.Web.Live.Originals.Variants.ShowLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals
  alias Attached.Variants

  @impl true
  def page_meta(socket, :show),
    do: %PageMeta{
      title: "#{socket.assigns.original.filename} — #{socket.assigns.variant.name}",
      path: dashboard_path(socket, ~p"/originals/#{socket.assigns.original.id}/variants/#{socket.assigns.variant.id}"),
      breadcrumb_title: "Variant '#{socket.assigns.variant.name}'",
      parent: AttachedDashboard.Web.Live.Originals.ShowLive.page_meta(socket, :show)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:actions>
          <Button.default :if={variant_url(@original, @variant)} variant="primary" href={variant_url(@original, @variant)} target="_blank">
            Download
          </Button.default>
          <Button.default
            variant="danger"
            phx-click={JS.push("purge_variant", value: %{id: @variant.id})}
            data-confirm="Purge this variant?"
          >
            Purge
          </Button.default>
        </:actions>
      </PageHeader.default>

      <Card.default class="mb-6">
        <:body>
          <div class="flex items-center gap-3 text-sm">
            <MimeIcon.type type={@variant.content_type} class="w-4 h-4 shrink-0 text-base-content/40" />
            <span class="text-base-content/60">Variant of</span>
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{@original.id}")} class="text-primary hover:underline font-medium">
              {@original.filename}
            </.link>
          </div>
        </:body>
      </Card.default>

      <div class="flex flex-col lg:flex-row gap-6 mb-6">
        <Card.default class="lg:w-80 shrink-0">
          <:title>Preview</:title>
          <:body>
            <img
              :if={variant_url(@original, @variant) && String.starts_with?(@variant.content_type, "image/")}
              src={variant_url(@original, @variant)}
              class="max-h-64 rounded border border-base-300"
              alt={@variant.name}
            />
            <p :if={is_nil(variant_url(@original, @variant))} class="text-base-content/40 text-sm">No URL available.</p>
            <div
              :if={variant_url(@original, @variant) && not String.starts_with?(@variant.content_type, "image/")}
              class="text-base-content/60 text-sm"
            >
              <a href={variant_url(@original, @variant)} class="text-primary hover:underline" target="_blank">Download</a>
            </div>
          </:body>
        </Card.default>

        <Card.default class="flex-1">
          <:title>Metadata</:title>
          <:body>
            <.meta_grid>
              <:item label="Name">{@variant.name}</:item>
              <:item label="Digest"><span class="font-mono text-xs">{@variant.transform_digest}</span></:item>
              <:item label="Storage Path"><span class="font-mono text-xs">{Variants.path_for(@original, @variant)}</span></:item>
              <:item label="Content Type">
                <div class="flex items-center gap-1.5">
                  <MimeIcon.type type={@variant.content_type} class="w-4 h-4 shrink-0 text-base-content/50" />
                  {@variant.content_type}
                </div>
              </:item>
              <:item label="Size">{format_bytes(@variant.byte_size)}</:item>
              <:item label="Created">{format_datetime(@variant.inserted_at)}</:item>
            </.meta_grid>

            <div :if={@variant.metadata != %{}}>
              <div class="border-t border-base-300 my-4" />
              <.meta_grid>
                <:item :for={{k, v} <- Enum.sort(@variant.metadata)} label={k}>
                  {if is_binary(v), do: v, else: inspect(v)}
                </:item>
              </.meta_grid>
            </div>
          </:body>
        </Card.default>
      </div>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(%{"original_id" => original_id, "id" => id}, _session, socket) do
    {:ok,
     socket
     |> assign(original: Originals.get!(original_id), variant: Variants.get!(id))
     |> PageMeta.assign_page_meta()}
  end

  @impl true
  def handle_event("purge_variant", %{"id" => id}, socket) do
    original_id = socket.assigns.original.id
    Variants.purge!(id)

    {:noreply,
     socket
     |> put_flash(:info, "Variant purged.")
     |> push_navigate(to: dashboard_path(socket, ~p"/originals/#{original_id}"))}
  end

  slot :item, required: true do
    attr :label, :string, required: true
  end

  defp meta_grid(assigns) do
    ~H"""
    <dl class="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
      <div :for={item <- @item}>
        <dt class="text-base-content/50">{item.label}</dt>
        <dd class="font-mono text-base-content break-all">{render_slot(item)}</dd>
      </div>
    </dl>
    """
  end

  defp variant_url(original, variant) do
    case Attached.original_url(Variants.path_for(original, variant)) do
      {:ok, url} -> url
      {:error, _reason} -> nil
    end
  end
end
