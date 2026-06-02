defmodule AttachedDashboard.Web.Components.Core.TableTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias AttachedDashboard.Web.Components.Core.Table

  defp rows, do: [%{id: "a", name: "Alpha"}, %{id: "b", name: "Bravo"}]

  defp col, do: [%{inner_block: fn _changed, row -> row.name end, label: "Name"}]

  defp checkbox_token, do: "type=" <> <<?">> <> "checkbox" <> <<?">>

  describe "without selection" do
    test "renders rows and does not emit a selection column" do
      html = render_component(&Table.default/1, id: "t", rows: rows(), col: col())

      assert html =~ "Alpha"
      assert html =~ "Bravo"
      refute html =~ checkbox_token()
    end
  end

  describe "with selection" do
    test "raises when :selected is set without :row_id" do
      assert_raise ArgumentError, ~r/requires :row_id/, fn ->
        render_component(&Table.default/1,
          id: "t",
          rows: rows(),
          selected: MapSet.new(),
          col: col()
        )
      end
    end

    test "renders row checkboxes, checked only for selected rows" do
      html =
        render_component(&Table.default/1,
          id: "t",
          rows: rows(),
          row_id: & &1.id,
          selected: MapSet.new(["a"]),
          on_toggle: "toggle",
          col: col()
        )

      # Each row's id is embedded in the phx-click JS.push value
      assert html =~ "&quot;id&quot;:&quot;a&quot;"
      assert html =~ "&quot;id&quot;:&quot;b&quot;"

      # Exactly one row-level checkbox (a) is checked
      row_checkboxes =
        Regex.scan(~r/<input[^>]*toggle[^>]*>/, html) |> List.flatten()

      checked_ones = Enum.filter(row_checkboxes, &String.contains?(&1, " checked"))
      assert length(checked_ones) == 1
      assert hd(checked_ones) =~ "&quot;id&quot;:&quot;a&quot;"
    end

    test "header checkbox is checked when every visible row is selected" do
      html =
        render_component(&Table.default/1,
          id: "t",
          rows: rows(),
          row_id: & &1.id,
          selected: MapSet.new(["a", "b"]),
          on_toggle_all: "toggle_all",
          col: col()
        )

      [header_input | _] =
        Regex.scan(~r/<input[^>]*>/, html) |> List.flatten()

      assert header_input =~ "checked"
    end

    test "header checkbox is unchecked when not all visible rows are selected" do
      html =
        render_component(&Table.default/1,
          id: "t",
          rows: rows(),
          row_id: & &1.id,
          selected: MapSet.new(["a"]),
          on_toggle_all: "toggle_all",
          col: col()
        )

      [header_input | _] =
        Regex.scan(~r/<input[^>]*>/, html) |> List.flatten()

      refute header_input =~ "checked"
    end

    test "header checkbox is disabled on empty page" do
      html =
        render_component(&Table.default/1,
          id: "t",
          rows: [],
          row_id: & &1.id,
          selected: MapSet.new(),
          on_toggle_all: "toggle_all",
          col: col()
        )

      assert html =~ "disabled"
      assert html =~ checkbox_token()
    end
  end
end
