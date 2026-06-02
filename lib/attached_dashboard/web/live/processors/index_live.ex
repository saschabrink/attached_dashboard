defmodule AttachedDashboard.Web.Live.Processors.IndexLive do
  @moduledoc false

  use AttachedDashboard.Web, :live_view

  @sections [
    %{
      title: "Metadata Extractors",
      description: "Read information about an original (dimensions, duration, bit rate, …) after upload and merge it into the original's metadata.",
      env_key: :metadata_extractors,
      registry: Attached.Processors.MetadataExtractors
    },
    %{
      title: "Image Previewers",
      description:
        "Render a preview image for a non-image original (PDF first page, video first frame) — enables image variants from non-image sources.",
      env_key: :image_previewers,
      registry: Attached.Processors.ImagePreviewers
    },
    %{
      title: "Transformers",
      description: "Convert an original from one format into another when producing variants — e.g. JPEG → WebP.",
      env_key: :transformers,
      registry: Attached.Processors.Transformers
    }
  ]

  @impl true
  def page_meta(socket, :index),
    do: %PageMeta{
      title: "Processors",
      path: dashboard_path(socket, ~p"/processors"),
      parent: AttachedDashboard.Web.Live.OverviewLive.page_meta(socket, :index)
    }

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.dashboard prefix={@prefix} page_meta={@page_meta} backlink={@backlink}>
      <PageHeader.default page_meta={@page_meta}>
        <:subtitle>Configured processors and their runtime availability</:subtitle>
      </PageHeader.default>

      <Card.default class="mb-6">
        <:body>
          <p class="text-sm text-base-content/60">
            Attached delegates format-specific work to pluggable processors.
            This page shows each registry's configured modules and whether their runtime
            dependencies (libvips, ImageMagick, ffmpeg, poppler, …) are installed on the host.
          </p>
        </:body>
      </Card.default>

      <div class="space-y-6">
        <.section :for={section <- @sections} section={section} />
      </div>
    </Layouts.dashboard>
    """
  end

  attr :section, :map, required: true

  defp section(assigns) do
    ~H"""
    <Card.default>
      <:title>
        <div class="flex items-center justify-between gap-4">
          <span>{@section.title}</span>
          <span class={[
            "text-xs font-normal px-2 py-0.5 rounded-full",
            if(@section.overridden?,
              do: "bg-primary/10 text-primary",
              else: "bg-base-200 text-base-content/60"
            )
          ]}>
            {if @section.overridden?, do: "Overridden via config", else: "Using defaults"}
          </span>
        </div>
      </:title>
      <:body>
        <p class="text-sm text-base-content/60 mb-3">{@section.description}</p>
        <p class="text-xs text-base-content/40 font-mono">
          config :attached, {inspect(@section.env_key)}
        </p>
      </:body>

      <div :if={@section.modules == []} class="px-5 pb-5 text-sm text-base-content/40">
        No modules configured.
      </div>

      <Table.default :if={@section.modules != []} id={"processors-#{@section.env_key}"} rows={@section.modules}>
        <:col :let={mod} label="Module" class="font-mono text-xs">
          {mod.short_name}
        </:col>
        <:col :let={mod} label="Description" class="text-sm text-base-content/60">
          <div>{mod.description}</div>
          <div class="mt-1 text-xs text-base-content/50">{mod.install_hint}</div>
        </:col>
        <:col :let={mod} label="Available" class="w-32">
          <span :if={mod.available?} class="inline-flex items-center gap-1 text-xs text-success">
            <span class="w-2 h-2 rounded-full bg-success" /> Available
          </span>
          <span :if={not mod.available?} class="inline-flex items-center gap-1 text-xs text-base-content/40">
            <span class="w-2 h-2 rounded-full bg-base-content/30" /> Not available
          </span>
        </:col>
      </Table.default>
    </Card.default>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, sections: Enum.map(@sections, &build_section/1))}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply, PageMeta.assign_page_meta(socket)}
  end

  defp build_section(section) do
    modules = section.registry.list()

    section
    |> Map.put(:overridden?, not is_nil(Application.get_env(:attached, section.env_key)))
    |> Map.put(:modules, Enum.map(modules, &module_row/1))
  end

  defp module_row(module) do
    %{
      module: module,
      short_name: short_name(module),
      description: moduledoc_first_paragraph(module),
      install_hint: safe_install_hint(module),
      available?: safe_available?(module)
    }
  end

  defp short_name(module) do
    module
    |> Module.split()
    |> Enum.drop_while(&(&1 != "Processors"))
    |> Enum.drop(2)
    |> Enum.join(".")
    |> case do
      "" -> inspect(module)
      short -> short
    end
  end

  defp moduledoc_first_paragraph(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, %{"en" => doc}, _, _} when is_binary(doc) ->
        doc
        |> String.split("\n\n", parts: 2)
        |> List.first()
        |> String.replace(~r/\s+/, " ")
        |> String.trim()

      _ ->
        ""
    end
  end

  defp safe_available?(module) do
    module.available?()
  rescue
    _ -> false
  end

  defp safe_install_hint(module) do
    module.install_hint()
  rescue
    _ -> ""
  end
end
