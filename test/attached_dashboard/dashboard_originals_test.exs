defmodule AttachedDashboard.Data.DashboardOriginalsTest do
  use AttachedDashboard.DataCase

  alias AttachedDashboard.Data.DashboardOriginals
  alias AttachedDashboard.Test.Factory

  describe "paginate/1" do
    test "returns all originals when no filters given" do
      Factory.insert(:original)
      Factory.insert(:original)

      result = DashboardOriginals.paginate()

      assert result.total == 2
      assert length(result.entries) == 2
    end

    test "search filters by filename (case-insensitive)" do
      Factory.insert(:original, filename: "invoice.pdf")
      Factory.insert(:original, filename: "PHOTO.jpg")
      Factory.insert(:original, filename: "other.txt")

      result = DashboardOriginals.paginate(search: "photo")

      assert result.total == 1
      assert {%{filename: "PHOTO.jpg"}, _count} = hd(result.entries)
    end

    test "search filters by key" do
      Factory.insert(:original, key: "uploads/abc123/file.pdf", filename: "unrelated.txt")
      Factory.insert(:original, key: "uploads/xyz/other.jpg", filename: "unrelated2.txt")

      result = DashboardOriginals.paginate(search: "abc123")

      assert result.total == 1
    end

    test "content_type filter matches prefix" do
      Factory.insert(:original, content_type: "image/jpeg")
      Factory.insert(:original, content_type: "image/png")
      Factory.insert(:original, content_type: "video/mp4")

      result = DashboardOriginals.paginate(content_type: "image")

      assert result.total == 2
    end

    test "storage_backend filter is exact match" do
      Factory.insert(:original, storage_backend: "local")
      Factory.insert(:original, storage_backend: "s3_main")

      result = DashboardOriginals.paginate(storage_backend: "local")

      assert result.total == 1
    end

    test "owner_table filter is exact match" do
      Factory.insert(:original, owner_table: "users")
      Factory.insert(:original, owner_table: "posts")

      result = DashboardOriginals.paginate(owner_table: "users")

      assert result.total == 1
    end

    test "empty search returns all originals" do
      Factory.insert(:original, filename: "a.pdf")
      Factory.insert(:original, filename: "b.pdf")

      result = DashboardOriginals.paginate(search: "")

      assert result.total == 2
    end

    test "pagination returns correct page" do
      for i <- 1..30, do: Factory.insert(:original, filename: "file#{i}.jpg")

      result = DashboardOriginals.paginate(page: 2)

      assert result.page == 2
      assert result.per_page == 25
      assert length(result.entries) == 5
    end
  end

  describe "parse_params/1" do
    test "defaults missing keys" do
      opts = DashboardOriginals.parse_params(%{})
      assert opts[:page] == 1
      assert opts[:sort_by] == "inserted_at"
      assert opts[:sort_dir] == "desc"
    end

    test "parses page from string" do
      assert DashboardOriginals.parse_params(%{"page" => "3"})[:page] == 3
    end

    test "falls back to page 1 on garbage input" do
      assert DashboardOriginals.parse_params(%{"page" => "oops"})[:page] == 1
      assert DashboardOriginals.parse_params(%{"page" => "0"})[:page] == 1
      assert DashboardOriginals.parse_params(%{"page" => "-5"})[:page] == 1
    end

    test "passes through filter fields" do
      opts =
        DashboardOriginals.parse_params(%{
          "search" => "foo",
          "content_type" => "image",
          "owner_table" => "users"
        })

      assert opts[:search] == "foo"
      assert opts[:content_type] == "image"
      assert opts[:owner_table] == "users"
    end
  end

  describe "paginate/1 sorting" do
    test "defaults to inserted_at desc" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      a = Factory.insert(:original, filename: "a.txt", inserted_at: DateTime.add(now, -10))
      b = Factory.insert(:original, filename: "b.txt", inserted_at: now)

      result = DashboardOriginals.paginate()

      assert [{%{id: first_id}, _}, {%{id: second_id}, _}] = result.entries
      assert first_id == b.id
      assert second_id == a.id
    end

    test "sorts by byte_size ascending" do
      small = Factory.insert(:original, byte_size: 10)
      large = Factory.insert(:original, byte_size: 1000)
      medium = Factory.insert(:original, byte_size: 500)

      result = DashboardOriginals.paginate(sort_by: "byte_size", sort_dir: "asc")

      assert [{%{id: a}, _}, {%{id: b}, _}, {%{id: c}, _}] = result.entries
      assert [a, b, c] == [small.id, medium.id, large.id]
    end

    test "sorts by filename" do
      Factory.insert(:original, filename: "zebra.txt")
      Factory.insert(:original, filename: "apple.txt")
      Factory.insert(:original, filename: "mango.txt")

      result = DashboardOriginals.paginate(sort_by: "filename", sort_dir: "asc")

      names = Enum.map(result.entries, fn {b, _} -> b.filename end)
      assert names == ["apple.txt", "mango.txt", "zebra.txt"]
    end

    test "unknown sort_by falls back to inserted_at" do
      now = DateTime.utc_now() |> DateTime.truncate(:second)
      a = Factory.insert(:original, inserted_at: DateTime.add(now, -10))
      b = Factory.insert(:original, inserted_at: now)

      result = DashboardOriginals.paginate(sort_by: "bogus")

      assert [{%{id: first}, _}, {%{id: second}, _}] = result.entries
      assert [first, second] == [b.id, a.id]
    end
  end
end
