defmodule AttachedDashboard.Web.Components.Layouts.SidebarTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AttachedDashboard.Web.Components.Layouts.Sidebar
  alias AttachedDashboard.Web.PageMeta

  defp meta, do: %PageMeta{path: "/files", title: "x"}

  describe "backlink" do
    test "renders the title as a link to the backlink path" do
      html =
        render_component(&Sidebar.dashboard/1,
          prefix: "/files",
          page_meta: meta(),
          backlink: "/admin"
        )

      assert html =~ ~s(href="/admin")
      assert html =~ "Attached Dashboard"
    end

    test "renders a plain title span when backlink is nil" do
      html =
        render_component(&Sidebar.dashboard/1,
          prefix: "/files",
          page_meta: meta(),
          backlink: nil
        )

      assert html =~ ~s(<span class="text-base font-bold text-primary tracking-tight">Attached Dashboard</span>)
    end

    test "title link uses href (full reload) not navigate, since backlink is outside the live_session" do
      html =
        render_component(&Sidebar.dashboard/1,
          prefix: "/files",
          page_meta: meta(),
          backlink: "/admin"
        )

      # No data-phx-link attribute on the title link — it's a regular <a href>.
      [title_link | _] = Regex.run(~r|<a[^>]*href="/admin"[^>]*>|, html) || [nil]
      assert title_link
      refute title_link =~ "data-phx-link"
    end
  end
end
