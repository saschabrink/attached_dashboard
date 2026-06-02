defmodule AttachedDashboard.Web.Components.PageHeader do
  @moduledoc false

  use Phoenix.Component

  alias AttachedDashboard.Web.Components.Breadcrumb
  alias AttachedDashboard.Web.PageMeta

  attr :page_meta, PageMeta, required: true
  attr :breadcrumbs, :boolean, default: true

  slot :title
  slot :subtitle
  slot :actions

  def default(assigns) do
    ~H"""
    <div class="mt-4 mb-8">
      <Breadcrumb.default :if={@breadcrumbs} page_meta={@page_meta} />
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-3 mt-3">
        <div>
          <%= if @title != [] do %>
            {render_slot(@title)}
          <% else %>
            <h1 class="text-2xl font-semibold tracking-tight leading-tight">
              {@page_meta.title}
            </h1>
          <% end %>
          <p :if={@subtitle != []} class="mt-1 font-mono text-sm text-base-content/50">
            {render_slot(@subtitle)}
          </p>
        </div>
        <div :if={@actions != []} class="flex items-center gap-2 shrink-0">
          {render_slot(@actions)}
        </div>
      </div>
    </div>
    """
  end
end
