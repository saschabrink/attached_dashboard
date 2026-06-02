defmodule AttachedDashboard.Web.Helpers.FormatTest do
  use ExUnit.Case, async: true

  import AttachedDashboard.Web.Helpers.Format

  describe "format_bytes/1" do
    test "nil returns em dash" do
      assert format_bytes(nil) == "—"
    end

    test "zero returns 0 B" do
      assert format_bytes(0) == "0 B"
    end

    test "bytes under 1024" do
      assert format_bytes(512) == "512 B"
    end

    test "kilobytes" do
      assert format_bytes(2048) == "2.0 KB"
    end

    test "megabytes" do
      assert format_bytes(5_242_880) == "5.0 MB"
    end

    test "gigabytes" do
      assert format_bytes(1_073_741_824) == "1.0 GB"
    end
  end

  describe "time_ago/1" do
    test "nil returns em dash" do
      assert time_ago(nil) == "—"
    end

    test "seconds ago" do
      dt = DateTime.add(DateTime.utc_now(), -30, :second)
      assert time_ago(dt) == "30s ago"
    end

    test "minutes ago" do
      dt = DateTime.add(DateTime.utc_now(), -120, :second)
      assert time_ago(dt) == "2m ago"
    end

    test "hours ago" do
      dt = DateTime.add(DateTime.utc_now(), -7200, :second)
      assert time_ago(dt) == "2h ago"
    end

    test "days ago" do
      dt = DateTime.add(DateTime.utc_now(), -172_800, :second)
      assert time_ago(dt) == "2d ago"
    end
  end
end
