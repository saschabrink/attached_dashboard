defmodule AttachedDashboard.Web.Live.PagesTest do
  use AttachedDashboard.ConnCase
  use Oban.Testing, repo: AttachedDashboard.TestRepo

  describe "overview page" do
    test "renders", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files")
      assert html =~ "Overview"
    end
  end

  describe "originals page" do
    test "renders", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/originals")
      assert html =~ "Originals"
    end

    test "submitting the filter form narrows by search", %{conn: conn} do
      AttachedDashboard.Test.Factory.insert(:original, filename: "keepme.pdf")
      AttachedDashboard.Test.Factory.insert(:original, filename: "other.pdf")

      {:ok, live, _html} = live(conn, "/files/originals")

      html =
        live
        |> form("form[phx-submit=filter]", %{"search" => "keepme"})
        |> render_submit()

      assert html =~ "keepme.pdf"
      refute html =~ "other.pdf"
    end

    test "storage_backend filter only shown when services exist", %{conn: conn} do
      AttachedDashboard.Test.Factory.insert(:original,
        storage_backend: "Attached.StorageBackends.Disk"
      )

      {:ok, _live, html} = live(conn, "/files/originals")
      assert html =~ ~s|name="storage_backend"|
      assert html =~ "Attached.StorageBackends.Disk"
    end

    test "sort_by select reflects the current sort", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/originals")
      # default sort is inserted_at desc
      assert html =~ ~r/<option value="inserted_at" selected[^>]*>Date<\/option>/
      assert html =~ ~r/<option value="desc" selected[^>]*>Desc<\/option>/
    end
  end

  describe "original detail page" do
    test "raises 404 for unknown id", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        live(conn, "/files/originals/00000000-0000-0000-0000-000000000000")
      end
    end

    test "renders original metadata fields in extra grid", %{conn: conn} do
      original =
        AttachedDashboard.Test.Factory.insert(:original,
          metadata: %{"width" => "1920", "height" => "1080", "color_space" => "sRGB"}
        )

      {:ok, _live, html} = live(conn, "/files/originals/#{original.id}")

      assert html =~ "width"
      assert html =~ "1920"
      assert html =~ "height"
      assert html =~ "1080"
      assert html =~ "color_space"
      assert html =~ "sRGB"
    end

    test "original page lists its variants with name and digest", %{conn: conn} do
      original = AttachedDashboard.Test.Factory.insert(:original, filename: "hero.jpg")

      _v1 =
        AttachedDashboard.Test.Factory.insert(:variant,
          original_id: original.id,
          name: "thumbnail",
          digest: "abcdef1234567890"
        )

      {:ok, _live, html} = live(conn, "/files/originals/#{original.id}")

      assert html =~ "Variants"
      assert html =~ "thumbnail"
      assert html =~ "abcdef1234567890"
    end
  end

  describe "variants page" do
    test "renders index", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/variants")
      assert html =~ "Variants"
    end

    test "lists each variant with its parent filename", %{conn: conn} do
      original = AttachedDashboard.Test.Factory.insert(:original, filename: "source.png")

      _variant =
        AttachedDashboard.Test.Factory.insert(:variant,
          original_id: original.id,
          name: "thumbnail"
        )

      {:ok, _live, html} = live(conn, "/files/variants")

      assert html =~ "thumbnail"
      assert html =~ "source.png"
    end

    test "variant detail shows parent link and breadcrumb chain", %{conn: conn} do
      original = AttachedDashboard.Test.Factory.insert(:original, filename: "hero.jpg")

      variant =
        AttachedDashboard.Test.Factory.insert(:variant,
          original_id: original.id,
          name: "small"
        )

      {:ok, _live, html} = live(conn, "/files/originals/#{original.id}/variants/#{variant.id}")

      assert html =~ "Variant of"
      assert html =~ "hero.jpg"
      assert html =~ "/files/originals/#{original.id}"
      # Breadcrumb segment
      assert html =~ "Variant &#39;small&#39;"
    end

    test "raises 404 for unknown variant id", %{conn: conn} do
      original = AttachedDashboard.Test.Factory.insert(:original)

      assert_raise Ecto.NoResultsError, fn ->
        live(conn, "/files/originals/#{original.id}/variants/00000000-0000-0000-0000-000000000000")
      end
    end
  end

  describe "owners page" do
    test "renders", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/owners")
      assert html =~ "Owners"
    end

    test "lists each (owner_table, owner_field) group with count", %{conn: conn} do
      AttachedDashboard.Test.Factory.insert(:original,
        owner_table: "test_owners",
        owner_field: "photo_attached_original_id"
      )

      AttachedDashboard.Test.Factory.insert(:original,
        owner_table: "test_owners",
        owner_field: "photo_attached_original_id"
      )

      AttachedDashboard.Test.Factory.insert(:original,
        owner_table: "other_owners",
        owner_field: "cover_attached_original_id"
      )

      {:ok, _live, html} = live(conn, "/files/owners")

      assert html =~ "test_owners"
      assert html =~ "photo_attached_original_id"
      assert html =~ "other_owners"
      assert html =~ "cover_attached_original_id"
      # Browse link carries the group into the originals filter.
      assert html =~ "owner_table=test_owners"
      assert html =~ "owner_field=photo_attached_original_id"
    end
  end

  describe "processors page" do
    test "renders each registry section with configured modules", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/processors")

      assert html =~ "Processors"
      assert html =~ "Transformers"
      assert html =~ "Metadata Extractors"
      assert html =~ "Image Previewers"

      # Built-in module short names appear in the tables (registry prefix
      # is stripped — the section title already disambiguates).
      assert html =~ "ImageMagick"
      assert html =~ "Image.Vix"
      assert html =~ "PDF"

      # Install hints are shown for every module so the page can double
      # as an install checklist.
      assert html =~ "precompiled libvips NIF"
      assert html =~ "brew install imagemagick"
      assert html =~ "brew install ffmpeg"
      assert html =~ "brew install poppler"
    end

    test "shows 'Using defaults' when no config override is set", %{conn: conn} do
      original = Application.get_env(:attached, :transformers)
      Application.delete_env(:attached, :transformers)

      on_exit(fn ->
        case original do
          nil -> Application.delete_env(:attached, :transformers)
          value -> Application.put_env(:attached, :transformers, value)
        end
      end)

      {:ok, _live, html} = live(conn, "/files/processors")
      assert html =~ "Using defaults"
    end

    test "shows 'Overridden via config' when :transformers is set explicitly", %{conn: conn} do
      original = Application.get_env(:attached, :transformers)
      Application.put_env(:attached, :transformers, [Attached.Processors.Transformers.Vix])

      on_exit(fn ->
        case original do
          nil -> Application.delete_env(:attached, :transformers)
          value -> Application.put_env(:attached, :transformers, value)
        end
      end)

      {:ok, _live, html} = live(conn, "/files/processors")
      assert html =~ "Overridden via config"
    end
  end

  describe "orphans page" do
    test "renders", %{conn: conn} do
      {:ok, _live, html} = live(conn, "/files/orphans")
      assert html =~ "Orphan"
    end

    test "toggling selection shows the purge-selected action", %{conn: conn} do
      AttachedDashboard.Test.Factory.insert(:original,
        owner_table: "test_owners",
        owner_field: "photo_attached_original_id"
      )

      {:ok, live, html} = live(conn, "/files/orphans")
      refute html =~ "Purge Selected"

      html =
        live
        |> element(~s|tr[id="test_owners::photo_attached_original_id"] input[type="checkbox"]|)
        |> render_click()

      assert html =~ "Purge Selected"
      assert html =~ "(1)"
    end

    test "purge_group enqueues a purge job for each original in the group", %{conn: conn} do
      original =
        AttachedDashboard.Test.Factory.insert(:original,
          owner_table: "test_owners",
          owner_field: "photo_attached_original_id"
        )

      {:ok, live, _html} = live(conn, "/files/orphans")

      render_click(live, "purge_group", %{
        "table" => "test_owners",
        "field" => "photo_attached_original_id"
      })

      assert_enqueued(worker: Attached.Originals.PurgeWorker, args: %{"original_id" => original.id})
    end

    test "purge_selected purges every selected group", %{conn: conn} do
      photo_original =
        AttachedDashboard.Test.Factory.insert(:original,
          owner_table: "test_owners",
          owner_field: "photo_attached_original_id"
        )

      avatar_original =
        AttachedDashboard.Test.Factory.insert(:original,
          owner_table: "test_owners",
          owner_field: "avatar_attached_original_id"
        )

      {:ok, live, _html} = live(conn, "/files/orphans")

      live
      |> element(~s|tr[id="test_owners::photo_attached_original_id"] input[type="checkbox"]|)
      |> render_click()

      live
      |> element(~s|tr[id="test_owners::avatar_attached_original_id"] input[type="checkbox"]|)
      |> render_click()

      render_click(live, "purge_selected", %{})

      assert_enqueued(
        worker: Attached.Originals.PurgeWorker,
        args: %{"original_id" => photo_original.id}
      )

      assert_enqueued(
        worker: Attached.Originals.PurgeWorker,
        args: %{"original_id" => avatar_original.id}
      )
    end

    test "purge_all enqueues the PurgeOrphans job", %{conn: conn} do
      AttachedDashboard.Test.Factory.insert(:original,
        owner_table: "test_owners",
        owner_field: "photo_attached_original_id"
      )

      {:ok, live, _html} = live(conn, "/files/orphans")

      render_click(live, "purge_all", %{})

      assert_enqueued(worker: Attached.Originals.PurgeOrphansWorker)
    end
  end
end
