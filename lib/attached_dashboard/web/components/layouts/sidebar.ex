defmodule AttachedDashboard.Web.Components.Layouts.Sidebar do
  @moduledoc false

  use AttachedDashboard.Web, :html

  alias AttachedDashboard.Web.Components.Core.Icon
  alias AttachedDashboard.Web.PageMeta

  attr :prefix, :string, required: true
  attr :page_meta, PageMeta, required: true
  attr :backlink, :string, default: nil

  def dashboard(assigns) do
    ~H"""
    <nav class="w-64 shrink-0 h-full flex flex-col pt-6 pb-5 px-3 bg-base-100 border border-base-300 rounded-lg shadow-sm">
      <div class="flex items-center justify-between px-2 mb-4">
        <.link
          :if={@backlink}
          href={@backlink}
          class="flex items-center gap-1.5 text-base font-bold text-primary tracking-tight hover:opacity-75 transition-opacity"
          title="Back to app"
        >
          <Icon.hero name={:arrow_left} class="w-4 h-4" /> Attached Dashboard
        </.link>
        <span :if={!@backlink} class="text-base font-bold text-primary tracking-tight">Attached Dashboard</span>
        <button
          class="sm:hidden p-1 rounded text-base-content/40 hover:text-base-content hover:bg-base-200"
          aria-label="Close menu"
          phx-click={
            Phoenix.LiveView.JS.hide(to: "#sidebar-backdrop")
            |> Phoenix.LiveView.JS.add_class("-translate-x-full", to: "#sidebar")
          }
        >
          <svg
            class="w-4 h-4"
            aria-hidden="true"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
            stroke-width="1.5"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      <div class="border-t border-base-300 mb-4" />
      <div class="flex-1 flex flex-col">
        <.nav_items page_meta={@page_meta}>
          <:item label="Overview" path={dashboard_path(@prefix, ~p"/")} icon={:squares_2x2} exact />
        </.nav_items>

        <.nav_items page_meta={@page_meta} group="Viewer">
          <:item label="Originals" path={dashboard_path(@prefix, ~p"/originals")} icon={:document} />
          <:item label="Variants" path={dashboard_path(@prefix, ~p"/variants")} icon={:photo} />
          <:item label="Owners" path={dashboard_path(@prefix, ~p"/owners")} icon={:users} />
        </.nav_items>

        <.nav_items page_meta={@page_meta} group="Cleanup">
          <:item label="Orphans" path={dashboard_path(@prefix, ~p"/orphans")} icon={:exclamation_triangle} />
        </.nav_items>

        <.nav_items page_meta={@page_meta} group="System">
          <:item label="Processors" path={dashboard_path(@prefix, ~p"/processors")} icon={:cog_6_tooth} />
        </.nav_items>
      </div>
      <.theme_toggle />
    </nav>
    """
  end

  attr :page_meta, PageMeta, required: true
  attr :group, :string, default: nil

  slot :item, required: true do
    attr :label, :string, required: true
    attr :path, :string, required: true
    attr :icon, :atom
    attr :exact, :boolean
  end

  defp nav_items(assigns) do
    ~H"""
    <div>
      <div
        :if={@group}
        class="px-3 mt-3 mb-2 text-xs font-semibold uppercase tracking-wider text-base-content/40"
      >
        {@group}
      </div>
      <ul>
        <li :for={item <- @item}>
          <.link
            navigate={item.path}
            class={[
              "flex items-center gap-2.5 px-3 py-2 rounded-md text-sm font-medium transition-colors",
              if(is_active?(@page_meta, item.path, Map.get(item, :exact, false)),
                do: "bg-primary/10 text-primary",
                else: "text-base-content/60 hover:bg-base-200 hover:text-base-content"
              )
            ]}
          >
            <Icon.hero :if={Map.get(item, :icon)} name={item.icon} class="w-4 h-4 shrink-0" />
            {item.label}
          </.link>
        </li>
      </ul>
    </div>
    """
  end

  defp theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center bg-base-200 rounded-full mt-4 text-xs">
      <div class="absolute w-1/3 h-full rounded-full bg-base-100 shadow-sm left-0 in-data-[theme=light]:left-1/3 in-data-[theme=dark]:left-2/3 transition-[left]" />
      <button
        class="flex-1 py-1.5 text-center cursor-pointer relative z-10 text-base-content/60 hover:text-base-content transition-colors"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        System
      </button>
      <button
        class="flex-1 py-1.5 text-center cursor-pointer relative z-10 text-base-content/60 hover:text-base-content transition-colors"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        Light
      </button>
      <button
        class="flex-1 py-1.5 text-center cursor-pointer relative z-10 text-base-content/60 hover:text-base-content transition-colors"
        phx-click={Phoenix.LiveView.JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        Dark
      </button>
    </div>
    """
  end

  defp is_active?(%PageMeta{path: current_path}, item_path, true),
    do: current_path == item_path

  defp is_active?(%PageMeta{path: current_path}, item_path, false),
    do: current_path == item_path or String.starts_with?(current_path, item_path <> "/")
end
