defmodule AttachedDashboard.Web.Components.Breadcrumb do
  @moduledoc false

  use Phoenix.Component

  alias AttachedDashboard.Web.PageMeta

  attr :page_meta, PageMeta, required: true

  def default(assigns) do
    assigns = assign(assigns, :breadcrumbs, PageMeta.breadcrumbs(assigns.page_meta))

    ~H"""
    <nav class="flex items-center gap-1.5 font-mono text-xs text-base-content/50">
      <.crumb
        :for={{crumb, index} <- Enum.with_index(@breadcrumbs)}
        title={elem(crumb, 0)}
        path={elem(crumb, 1)}
        first={index == 0}
      />
    </nav>
    """
  end

  defp crumb(%{path: nil, first: true} = assigns) do
    ~H"""
    <span class="text-base-content">{@title}</span>
    """
  end

  defp crumb(%{path: nil} = assigns) do
    ~H"""
    <span class="text-base-content">{@title}</span>
    """
  end

  defp crumb(%{first: true} = assigns) do
    ~H"""
    <.link navigate={@path} class="hover:text-base-content transition-colors">{@title}</.link>
    <span aria-hidden="true" class="text-base-content/30">›</span>
    """
  end

  defp crumb(assigns) do
    ~H"""
    <.link navigate={@path} class="hover:text-base-content transition-colors">{@title}</.link>
    <span aria-hidden="true" class="text-base-content/30">›</span>
    """
  end
end
