defmodule AttachedDashboard.Web.Live.Originals.ShowLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  alias Attached.Originals
  alias Attached.Variants

  @impl true
  def page_meta(socket, :show) do
    original = socket.assigns.original
    index_meta = AttachedDashboard.Web.Live.Originals.IndexLive.page_meta(socket, :index)

    %PageMeta{
      title: original.filename,
      path: dashboard_path(socket, ~p"/originals/#{original.id}"),
      breadcrumb_title: String.slice(original.filename, 0, 30),
      parent: index_meta
    }
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:actions>
          <Button.default :if={@original_url} variant="primary" href={@original_url} download={@original.filename} target="_blank">
            Download
          </Button.default>
          <Button.default variant="secondary" phx-click={JS.push("reanalyze_original", value: %{id: @original.id})}>Re-analyze</Button.default>
          <Button.default
            variant="danger"
            phx-click={JS.push("purge_original", value: %{id: @original.id})}
            data-confirm="Purge this original and all its variants?"
          >
            Purge
          </Button.default>
        </:actions>
      </PageHeader.default>

      <div class="flex flex-col lg:flex-row gap-6 mb-6">
        <%!-- Preview --%>
        <Card.default class="lg:w-80 shrink-0">
          <:title>Preview</:title>
          <:body><.original_preview original={@original} url={@original_url} preview_url={@preview_url} /></:body>
        </Card.default>

        <%!-- Metadata --%>
        <Card.default class="flex-1">
          <:title>Metadata</:title>
          <:body>
            <.meta_grid>
              <:item label="Key">{@original.key}</:item>
              <:item label="Content Type">
                <div class="flex items-center gap-1.5">
                  <MimeIcon.type type={@original.content_type} class="w-4 h-4 shrink-0 text-base-content/50" />
                  {@original.content_type}
                </div>
              </:item>
              <:item label="Storage Backend">{@original.storage_backend}</:item>
              <:item label="Size">{format_bytes(@original.byte_size)}</:item>
              <:item label="Checksum">{@original.checksum}</:item>
              <:item label="Owner">{"#{@original.owner_table}.#{@original.owner_field}"}</:item>
              <:item label="Uploaded">{format_datetime(@original.inserted_at)}</:item>
            </.meta_grid>

            <div :if={@original.metadata != %{}}>
              <div class="border-t border-base-300 my-4" />
              <.meta_grid>
                <:item
                  :for={{k, v} <- Enum.sort(@original.metadata)}
                  label={k}
                >
                  {if is_binary(v), do: v, else: inspect(v)}
                </:item>
              </.meta_grid>
            </div>
          </:body>
        </Card.default>
      </div>

      <%!-- Variants --%>
      <Card.default :if={@original.variants != []} class="mb-6">
        <:title>Variants</:title>
        <Table.default
          id="original-variants"
          rows={@original.variants}
          row_click={fn vr -> JS.navigate(dashboard_path(@prefix, ~p"/originals/#{@original.id}/variants/#{vr.id}")) end}
        >
          <:col :let={vr} label="Name">
            <.link navigate={dashboard_path(@prefix, ~p"/originals/#{@original.id}/variants/#{vr.id}")} class="text-primary hover:underline">
              {vr.name}
            </.link>
          </:col>
          <:col :let={vr} label="Content Type" class="text-base-content/50 text-xs">{vr.content_type}</:col>
          <:col :let={vr} label="Size">
            {format_bytes(vr.byte_size)}
          </:col>
          <:col :let={vr} label="Digest" class="font-mono text-xs text-base-content/40">
            {String.slice(vr.transform_digest, 0, 16)}…
          </:col>
          <:action :let={vr}>
            <Button.default variant="danger" phx-click={JS.push("purge_variant", value: %{id: vr.id})}>Purge</Button.default>
          </:action>
        </Table.default>
      </Card.default>

      <%!-- Owner lookup --%>
      <Card.default :if={@owner_row} class="mb-6">
        <:title>Owner Record</:title>
        <:body>
          <p class="text-xs text-base-content/40 mb-2">
            From <code class="bg-base-200 px-1 rounded">{@original.owner_table}</code>
          </p>
          <pre class="text-xs bg-base-200 rounded p-3 overflow-auto"><%= inspect(@owner_row, pretty: true) %></pre>
        </:body>
      </Card.default>
    </Layouts.dashboard>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    original = Originals.get!(id, preload: [:variants])

    {:ok,
     socket
     |> assign(
       original: original,
       original_url: safe_original_url(original),
       preview_url: safe_preview_url(original),
       owner_row: Originals.get_owner(original)
     )
     |> PageMeta.assign_page_meta()}
  end

  @impl true
  def handle_event("purge_original", %{"id" => id}, socket) do
    Originals.purge_later(id)

    {:noreply,
     socket
     |> put_flash(:info, "Purge job enqueued.")
     |> push_navigate(to: dashboard_path(socket, ~p"/originals"))}
  end

  def handle_event("reanalyze_original", %{"id" => id}, socket) do
    Originals.extract_metadata_later(id)
    {:noreply, put_flash(socket, :info, "Re-analyze job enqueued.")}
  end

  def handle_event("purge_variant", %{"id" => id}, socket) do
    Variants.purge!(id)
    original = Originals.get!(socket.assigns.original.id, preload: :variants)

    {:noreply,
     socket
     |> assign(original: original, original_url: safe_original_url(original), owner_row: Originals.get_owner(original))
     |> put_flash(:info, "Variant purged.")}
  end

  attr :original, :map, required: true
  attr :url, :string, default: nil
  attr :preview_url, :string, default: nil

  defp original_preview(%{original: %{content_type: "video/" <> _}} = assigns) do
    ~H"""
    <video :if={@url} controls class="max-h-64 rounded">
      <source src={@url} type={@original.content_type} />
    </video>
    <p :if={is_nil(@url)} class="text-base-content/40 text-sm">No URL available.</p>
    """
  end

  defp original_preview(%{original: %{content_type: "audio/" <> _}} = assigns) do
    ~H"""
    <audio :if={@url} controls>
      <source src={@url} type={@original.content_type} />
    </audio>
    <p :if={is_nil(@url)} class="text-base-content/40 text-sm">No URL available.</p>
    """
  end

  defp original_preview(%{preview_url: url} = assigns) when is_binary(url) do
    ~H"""
    <img
      src={@preview_url}
      class="max-h-64 rounded border border-base-300"
      alt={@original.filename}
    />
    """
  end

  defp original_preview(assigns) do
    ~H"""
    <div class="flex items-center gap-3 text-base-content/60">
      <span class="text-2xl">📄</span>
      <a :if={@url} href={@url} class="text-primary hover:underline text-sm" target="_blank">
        Download {@original.filename}
      </a>
      <span :if={is_nil(@url)} class="text-sm">{@original.filename}</span>
    </div>
    """
  end

  slot :item, required: true do
    attr :label, :string, required: true
    attr :href, :string
  end

  defp meta_grid(assigns) do
    ~H"""
    <dl class="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
      <div :for={item <- @item}>
        <dt class="text-base-content/50">{item.label}</dt>
        <dd class="font-mono text-base-content break-all">
          <a :if={Map.get(item, :href)} href={item.href} class="text-primary hover:underline">
            {render_slot(item)}
          </a>
          <span :if={!Map.get(item, :href)}>{render_slot(item)}</span>
        </dd>
      </div>
    </dl>
    """
  end

  defp safe_original_url(original) do
    case Attached.original_url(original.key) do
      {:ok, url} -> url
      {:error, _reason} -> nil
    end
  end

  defp safe_preview_url(original) do
    case Variants.preview_url(original) do
      {:ok, url} -> url
      {:error, _reason} -> nil
    end
  end
end
