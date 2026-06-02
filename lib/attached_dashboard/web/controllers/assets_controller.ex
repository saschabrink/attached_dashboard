defmodule AttachedDashboard.Web.Controllers.AssetsController do
  @moduledoc false

  use Phoenix.Controller, formats: [:html]

  plug :skip_csrf_protection

  def asset(conn, %{"filename" => parts}) do
    filename = Path.join(parts)

    if filename in Map.values(manifest()) do
      priv = :code.priv_dir(:attached_dashboard)

      conn
      |> put_resp_header("content-type", MIME.from_path(filename))
      |> put_resp_header("cache-control", "public, max-age=31536000, immutable")
      |> send_file(200, Path.join([priv, "static", filename]))
    else
      conn |> put_status(404) |> text("not found")
    end
  end

  @doc false
  def asset_path(original), do: manifest()[original] || original

  defp skip_csrf_protection(conn, _opts),
    do: Plug.Conn.put_private(conn, :plug_skip_csrf_protection, true)

  defp manifest do
    path = :attached_dashboard |> :code.priv_dir() |> Path.join("static/manifest.json")

    if File.exists?(path) do
      Jason.decode!(File.read!(path))
    else
      raise "AttachedDashboard assets not built. Run: mix attached_dashboard.build_assets"
    end
  end
end
