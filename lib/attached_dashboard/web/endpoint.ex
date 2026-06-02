defmodule AttachedDashboard.Web.Endpoint do
  @moduledoc false

  # Stub endpoint used exclusively by `Phoenix.VerifiedRoutes` for compile-time
  # path validation. Never dispatched against — the real endpoint is always the
  # host app's endpoint.
  #
  # The `~p` sigil in `AttachedDashboard.Web` LiveViews validates paths against
  # `AttachedDashboard.Web.Router` and expands to runtime calls that go through
  # this endpoint's `script_name/0` and `path/1`. Since the dashboard is always
  # mounted at a host-configured prefix (handled separately via `@prefix`), we
  # want `~p"/originals/#{id}"` to produce exactly `/originals/#{id}` — so this stub
  # returns the path unmodified with an empty script_name.

  def script_name, do: []
  def path(path), do: path
  def static_path(path), do: path
  def static_url, do: ""
  def static_integrity(_path), do: nil
  def url, do: ""
  def config(:static_url), do: [path: "/"]
  def config(_), do: nil
end
