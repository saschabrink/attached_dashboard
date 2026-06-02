defmodule Mix.Tasks.AttachedDashboard.BuildAssets do
  @shortdoc "Builds CSS and JS assets for AttachedDashboard"

  @moduledoc """
  Builds and hashes the CSS and JS assets for the AttachedDashboard.

      mix attached_dashboard.build_assets

  Steps:
  1. Runs Tailwind CSS (v4) to compile `assets/css/app.css`.
  2. Runs esbuild to bundle `assets/js/app.js`.
  3. MD5-hashes the output files and renames them to `app-<md5>.css` / `app-<md5>.js`.
  4. Writes `priv/static/manifest.json`.
  """

  use Mix.Task

  @priv_static "priv/static"
  @assets_static "assets/static"

  @impl Mix.Task
  def run(_args) do
    static_dir = Path.expand(@priv_static, app_dir())

    File.rm_rf!(static_dir)
    File.mkdir_p!(Path.join(static_dir, "css"))
    File.mkdir_p!(Path.join(static_dir, "js"))

    run_tailwind()
    run_esbuild()

    {css_hash, js_hash} = hash_and_rename(static_dir)
    static_hashes = copy_static(static_dir)
    write_manifest(static_dir, css_hash, js_hash, static_hashes)

    Mix.shell().info("AttachedDashboard assets built: css=#{css_hash} js=#{js_hash}")
  end

  defp app_dir, do: File.cwd!()

  defp run_tailwind do
    Mix.shell().info("Building CSS...")
    apply(Tailwind, :run, [:attached_dashboard, ~w(--minify)])
  end

  defp run_esbuild do
    Mix.shell().info("Building JS...")
    apply(Esbuild, :run, [:attached_dashboard, ~w(--minify)])
  end

  defp hash_and_rename(static_dir) do
    css_path = Path.join([static_dir, "css", "app.css"])
    js_path = Path.join([static_dir, "js", "app.js"])

    css_hash = md5_file(css_path)
    js_hash = md5_file(js_path)

    File.rename!(css_path, Path.join([static_dir, "css", "app-#{css_hash}.css"]))
    File.rename!(js_path, Path.join([static_dir, "js", "app-#{js_hash}.js"]))

    {css_hash, js_hash}
  end

  defp md5_file(path), do: path |> File.read!() |> md5()
  defp md5(content), do: content |> then(&:crypto.hash(:md5, &1)) |> Base.encode16(case: :lower)

  defp copy_static(static_dir) do
    assets_static_dir = Path.expand(@assets_static, app_dir())

    for filename <- File.ls!(assets_static_dir), into: %{} do
      src = Path.join(assets_static_dir, filename)
      content = File.read!(src)
      hash = md5(content)
      ext = Path.extname(filename)
      base = Path.basename(filename, ext)
      File.cp!(src, Path.join(static_dir, "#{base}-#{hash}#{ext}"))
      {filename, hash}
    end
  end

  defp write_manifest(static_dir, css_hash, js_hash, static_hashes) do
    built = %{
      "css/app.css" => "css/app-#{css_hash}.css",
      "js/app.js" => "js/app-#{js_hash}.js"
    }

    static =
      Map.new(static_hashes, fn {filename, hash} ->
        ext = Path.extname(filename)
        base = Path.basename(filename, ext)
        {filename, "#{base}-#{hash}#{ext}"}
      end)

    path = Path.join(static_dir, "manifest.json")
    File.write!(path, Jason.encode!(Map.merge(built, static), pretty: true))
  end
end
