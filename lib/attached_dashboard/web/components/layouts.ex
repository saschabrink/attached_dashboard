defmodule AttachedDashboard.Web.Components.Layouts do
  @moduledoc false

  use Phoenix.Component

  alias AttachedDashboard.Web.Components.Layouts.Sidebar
  alias AttachedDashboard.Web.Controllers.AssetsController

  embed_templates "layouts/*"

  slot :inner_block, required: true
  def root(assigns)

  attr :prefix, :string, required: true
  attr :page_meta, AttachedDashboard.Web.PageMeta, required: true
  attr :backlink, :string, default: nil
  slot :inner_block, required: true
  def dashboard(assigns)
end
