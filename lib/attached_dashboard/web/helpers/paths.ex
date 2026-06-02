defmodule AttachedDashboard.Web.Helpers.Paths do
  @moduledoc false

  @doc """
  Prepends the mount prefix to a verified route.

  Accepts a socket, an assigns map, or a bare prefix string. Use with `~p`:

      dashboard_path(socket, ~p"/originals/\#{id}")   # in callbacks
      dashboard_path(@prefix, ~p"/originals")         # in templates
  """
  def dashboard_path(%{assigns: %{prefix: prefix}}, path), do: prefix <> path
  def dashboard_path(%{prefix: prefix}, path), do: prefix <> path
  def dashboard_path(prefix, path) when is_binary(prefix), do: prefix <> path
end
