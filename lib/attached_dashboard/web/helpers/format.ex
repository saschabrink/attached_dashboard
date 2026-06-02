defmodule AttachedDashboard.Web.Helpers.Format do
  @moduledoc false

  @doc "Formats a byte size into a human-readable string."
  def format_bytes(nil), do: "—"
  def format_bytes(0), do: "0 B"

  def format_bytes(bytes) when is_integer(bytes) do
    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 1)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 1)} MB"
      bytes >= 1_024 -> "#{Float.round(bytes / 1_024, 1)} KB"
      true -> "#{bytes} B"
    end
  end

  @doc "Returns a relative time string like '3 minutes ago'."
  def time_ago(nil), do: "—"

  def time_ago(%DateTime{} = dt) do
    diff = DateTime.diff(DateTime.utc_now(), dt, :second)
    format_diff(diff)
  end

  def time_ago(%NaiveDateTime{} = ndt) do
    time_ago(DateTime.from_naive!(ndt, "Etc/UTC"))
  end

  defp format_diff(s) when s < 60, do: "#{s}s ago"
  defp format_diff(s) when s < 3_600, do: "#{div(s, 60)}m ago"
  defp format_diff(s) when s < 86_400, do: "#{div(s, 3_600)}h ago"
  defp format_diff(s), do: "#{div(s, 86_400)}d ago"

  @doc "Formats a UTC datetime for display."
  def format_datetime(nil), do: "—"

  def format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  def format_datetime(%NaiveDateTime{} = ndt) do
    Calendar.strftime(ndt, "%Y-%m-%d %H:%M")
  end
end
