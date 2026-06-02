defmodule AttachedDashboard.Web do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView

      @behaviour AttachedDashboard.Web.PageMeta
      import AttachedDashboard.Web.PageMeta, only: [assign_page_meta: 1]

      alias AttachedDashboard.Web.Components.Layouts

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      unquote(html_helpers())
    end
  end

  defp html_helpers do
    quote do
      use Phoenix.VerifiedRoutes,
        router: AttachedDashboard.Web.Router,
        endpoint: AttachedDashboard.Web.Endpoint,
        statics: []

      import AttachedDashboard.Web.Components.Core
      import AttachedDashboard.Web.Helpers.Format
      import AttachedDashboard.Web.Helpers.Paths

      alias AttachedDashboard.Web.Components.Breadcrumb
      alias AttachedDashboard.Web.PageMeta
      alias AttachedDashboard.Web.Components.Core.Button
      alias AttachedDashboard.Web.Components.Core.Card
      alias AttachedDashboard.Web.Components.Core.Icon
      alias AttachedDashboard.Web.Components.Core.Table
      alias AttachedDashboard.Web.Components.Flash
      alias AttachedDashboard.Web.Components.MimeIcon
      alias AttachedDashboard.Web.Components.PageHeader
      alias Phoenix.LiveView.JS
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
