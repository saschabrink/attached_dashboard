# Supporting modules (Repo/Router/Endpoint/…) only compile in :screenshots
# env — they pull in SQLite/plug_cowboy/wallaby which aren't available
# in :dev/:test/:prod.
if Mix.env() == :screenshots do
  defmodule AttachedDashboard.Screenshots.ErrorHTML do
    @moduledoc false
    def render("500.html", _), do: "Internal Server Error"
    def render("404.html", _), do: "Not Found"
  end

  defmodule AttachedDashboard.Screenshots.Repo do
    @moduledoc false
    use Ecto.Repo, otp_app: :attached_dashboard, adapter: Ecto.Adapters.SQLite3
  end

  defmodule AttachedDashboard.Screenshots.Router do
    @moduledoc false
    use Phoenix.Router
    import AttachedDashboard.Web.Router

    pipeline :browser do
      plug :accepts, ["html"]
      plug :fetch_session
      plug :put_root_layout, {AttachedDashboard.Web.Components.Layouts, :root}
    end

    scope "/" do
      pipe_through :browser
      attached_dashboard("/files")
    end
  end

  defmodule AttachedDashboard.Screenshots.Endpoint do
    @moduledoc false
    use Phoenix.Endpoint, otp_app: :attached_dashboard

    socket "/live", Phoenix.LiveView.Socket

    plug Plug.Session,
      store: :cookie,
      key: "_attached_dashboard_screenshots_key",
      signing_salt: "attached_dashboard_shots!!"

    plug AttachedDashboard.Screenshots.Router
  end

  defmodule AttachedDashboard.Screenshots.AttachedMigration do
    @moduledoc false
    use Ecto.Migration
    def up, do: Attached.Ecto.Migration.up()
    def down, do: Attached.Ecto.Migration.down()
  end

  defmodule AttachedDashboard.Screenshots.ObanMigration do
    @moduledoc false
    use Ecto.Migration
    def change, do: Oban.Migration.up(version: 12)
  end
end

defmodule Mix.Tasks.AttachedDashboard.Screenshots do
  @shortdoc "Generates dashboard documentation screenshots via headless Chromium"

  @moduledoc """
  Generates PNG screenshots of every dashboard page into `docs/screenshots/`.

  Boots a self-contained Phoenix endpoint against an in-memory SQLite repo,
  seeds deterministic fixtures, then drives a Chromium-based browser via
  Wallaby.

  Manual task — not wired into CI. Run locally whenever the UI changes and
  commit the updated PNGs.

      mix attached_dashboard.screenshots

  (The task forces `MIX_ENV=screenshots` via preferred_envs, so you do not
  need to set it manually.)

  Requires:

    * `chromedriver` on PATH (provided by the Nix flake)
    * A Chromium-based browser on the host — Helium, Chrome, Chromium,
      Brave, or Arc. Auto-detected, or set `CHROME_BINARY=/path/to/binary`.

  Everything screenshot-specific (Endpoint, Router, Repo, seed data, browser
  config) lives in this file — the test suite is untouched.
  """

  use Mix.Task

  # Supporting modules + Wallaby only exist in :screenshots env; silence
  # compile warnings when this task is compiled elsewhere. The task
  # raises at runtime if invoked outside :screenshots.
  @compile {:no_warn_undefined,
            [
              AttachedDashboard.Screenshots.Endpoint,
              AttachedDashboard.Screenshots.Repo,
              AttachedDashboard.Screenshots.AttachedMigration,
              AttachedDashboard.Screenshots.ObanMigration,
              AttachedDashboard.Screenshots.ErrorHTML,
              Wallaby,
              Wallaby.Browser,
              Wallaby.Chrome
            ]}

  alias AttachedDashboard.Screenshots.{AttachedMigration, Endpoint, Repo, ObanMigration}
  alias Attached.Originals.Original
  alias Attached.Variants.Variant
  import Ecto.Query

  @port 4737
  @base_url "http://localhost:#{@port}"
  @output_dir "docs/screenshots"
  @window_size [width: 1440, height: 900]

  @impl Mix.Task
  def run(_args) do
    unless Mix.env() == :screenshots do
      Mix.raise("Run with: mix attached_dashboard.screenshots (forces MIX_ENV=screenshots)")
    end

    Mix.Task.run("app.config")
    Application.ensure_all_started(:phoenix)
    Application.ensure_all_started(:phoenix_live_view)

    File.mkdir_p!(@output_dir)

    configure_wallaby!()
    {:ok, _} = Application.ensure_all_started(:wallaby)

    boot_app!()
    seed!()

    {:ok, session} = Wallaby.start_session(window_size: @window_size)

    shots = [
      {"overview", "/files"},
      {"originals_index", "/files/originals"},
      {"variants_index", "/files/variants"},
      {"owners_index", "/files/owners"},
      {"processors_index", "/files/processors"},
      {"orphans_index", "/files/orphans"}
    ]

    Enum.each(shots, fn {name, path} ->
      Mix.shell().info("  → #{name} (#{path})")

      session
      |> Wallaby.Browser.visit(@base_url <> path)
      |> take_shot(name)
    end)

    hero = Repo.one(from b in Original, where: b.filename == "hero-banner.jpg")

    variant =
      hero &&
        Repo.one(
          from v in Variant,
            where: v.original_id == ^hero.id and v.name == "medium"
        )

    if hero do
      Mix.shell().info("  → originals_show")

      session
      |> Wallaby.Browser.visit(@base_url <> "/files/originals/#{hero.id}")
      |> take_shot("originals_show")
    end

    if variant do
      Mix.shell().info("  → variants_show")

      session
      |> Wallaby.Browser.visit(@base_url <> "/files/originals/#{variant.original_id}/variants/#{variant.id}")
      |> take_shot("variants_show")
    end

    Wallaby.end_session(session)
    Mix.shell().info("\nDone. Screenshots in #{@output_dir}/")
  end

  # --------------------------------------------------------------------------
  # App boot
  # --------------------------------------------------------------------------

  defp boot_app! do
    Application.put_env(:attached_dashboard, Endpoint,
      check_origin: false,
      live_view: [signing_salt: "attached_dashboard_shot_salt!!"],
      render_errors: [formats: [html: AttachedDashboard.Screenshots.ErrorHTML], layout: false],
      secret_key_base: String.duplicate("a", 64),
      server: true,
      http: [port: @port],
      url: [host: "localhost", port: @port]
    )

    {:ok, _} = Repo.start_link()
    migrate!()

    {:ok, _} = Application.ensure_all_started(:oban)

    {:ok, _} =
      Oban.start_link(
        name: Oban,
        repo: Repo,
        engine: Oban.Engines.Lite,
        testing: :manual,
        queues: false,
        plugins: false
      )

    {:ok, _} = Endpoint.start_link()
    :ok
  end

  defp migrate! do
    # Canonical schema for `attached_originals` — same migration real apps run.
    Ecto.Migrator.up(Repo, 0, AttachedMigration, log: false)
    Ecto.Migrator.up(Repo, 1, ObanMigration, log: false)

    # Fake owner tables the `seed!/0` fixture references. Non-ghost tables
    # get populated with a row per original so those originals look "alive" to the
    # orphan detector; `ghost_owners` stays empty so its two originals show up
    # as orphans on the dashboard.
    sql = fn q -> Ecto.Adapters.SQL.query!(Repo, q) end

    for {table, fields} <- owner_tables() do
      columns = Enum.map_join(fields, ",\n          ", &"#{&1} TEXT")

      sql.("""
        CREATE TABLE IF NOT EXISTS #{table} (
          id TEXT PRIMARY KEY,
          #{columns}
        )
      """)
    end

    :ok
  end

  defp owner_tables do
    [
      {"posts", ["cover_attached_original_id"]},
      {"users", ["avatar_attached_original_id"]},
      {"documents", ["file_attached_original_id"]},
      {"lessons", ["intro_attached_original_id"]},
      {"ghost_owners", ["photo_attached_original_id", "avatar_attached_original_id"]}
    ]
  end

  # --------------------------------------------------------------------------
  # Seed data — deterministic realistic fixture
  # --------------------------------------------------------------------------

  defp seed! do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    hero =
      insert_original_with_owner!(
        filename: "hero-banner.jpg",
        content_type: "image/jpeg",
        byte_size: 482_117,
        storage_backend: "Attached.StorageBackends.Disk",
        metadata: %{"width" => "1920", "height" => "1080", "color_space" => "sRGB"},
        owner_table: "posts",
        owner_field: "cover_attached_original_id",
        inserted_at: shift(now, -3600 * 2)
      )

    insert_original_with_owner!(
      filename: "profile-photo.png",
      content_type: "image/png",
      byte_size: 94_321,
      storage_backend: "Attached.StorageBackends.Disk",
      metadata: %{"width" => "512", "height" => "512"},
      owner_table: "users",
      owner_field: "avatar_attached_original_id",
      inserted_at: shift(now, -3600 * 4)
    )

    insert_original_with_owner!(
      filename: "terms-2026.pdf",
      content_type: "application/pdf",
      byte_size: 218_440,
      storage_backend: "Attached.StorageBackends.S3",
      metadata: %{"page_count" => "14"},
      owner_table: "documents",
      owner_field: "file_attached_original_id",
      inserted_at: shift(now, -3600 * 24)
    )

    insert_original_with_owner!(
      filename: "intro-video.mp4",
      content_type: "video/mp4",
      byte_size: 8_421_330,
      storage_backend: "Attached.StorageBackends.S3",
      metadata: %{"duration" => "42.1", "width" => "1280", "height" => "720"},
      owner_table: "lessons",
      owner_field: "intro_attached_original_id",
      inserted_at: shift(now, -3600 * 48)
    )

    insert_variant!(hero,
      name: "thumbnail",
      content_type: "image/webp",
      byte_size: 18_210,
      metadata: %{"width" => "240", "height" => "135"}
    )

    insert_variant!(hero,
      name: "medium",
      content_type: "image/webp",
      byte_size: 74_904,
      metadata: %{"width" => "800", "height" => "450"}
    )

    # Orphans — originals whose owner row is gone
    insert_original!(
      filename: "abandoned-upload.png",
      content_type: "image/png",
      byte_size: 12_004,
      owner_table: "ghost_owners",
      owner_field: "photo_attached_original_id",
      inserted_at: shift(now, -3600 * 72)
    )

    insert_original!(
      filename: "abandoned-avatar.jpg",
      content_type: "image/jpeg",
      byte_size: 33_110,
      owner_table: "ghost_owners",
      owner_field: "avatar_attached_original_id",
      inserted_at: shift(now, -3600 * 96)
    )

    :ok
  end

  # Inserts an original AND a corresponding row in its owner table, so the
  # orphan detector treats the original as "alive". Use `insert_original!` directly
  # to leave the owner side missing (→ orphan).
  defp insert_original_with_owner!(attrs) do
    original = insert_original!(attrs)
    attrs = Map.new(attrs)

    Ecto.Adapters.SQL.query!(
      Repo,
      "INSERT INTO #{Map.fetch!(attrs, :owner_table)} (id, #{Map.fetch!(attrs, :owner_field)}) VALUES (?, ?)",
      [Ecto.UUID.generate(), original.id]
    )

    original
  end

  defp insert_original!(attrs) do
    attrs = Map.new(attrs)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Original{}
    |> Ecto.Changeset.change(
      Map.merge(
        %{
          id: Ecto.UUID.generate(),
          key: "key-#{System.unique_integer([:positive])}",
          checksum: "abc123==",
          metadata: %{},
          storage_backend: "Attached.StorageBackends.Disk",
          inserted_at: now,
          updated_at: now
        },
        attrs
      )
    )
    |> Repo.insert!()
  end

  defp insert_variant!(%Original{} = parent, attrs) do
    attrs = Map.new(attrs)
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    %Variant{}
    |> Ecto.Changeset.change(
      Map.merge(
        %{
          id: Ecto.UUID.generate(),
          original_id: parent.id,
          transform_digest: "digest#{System.unique_integer([:positive])}",
          checksum: "seed==",
          inserted_at: now,
          updated_at: now
        },
        attrs
      )
    )
    |> Repo.insert!()
  end

  defp shift(dt, seconds), do: DateTime.add(dt, seconds, :second)

  # --------------------------------------------------------------------------
  # Wallaby / Chromium config
  # --------------------------------------------------------------------------

  defp take_shot(session, name) do
    # Give LiveView a moment to settle (initial render + connect).
    Process.sleep(400)
    Wallaby.Browser.take_screenshot(session, name: name)
    canonical = Path.join(@output_dir, "#{name}.png")

    unless File.exists?(canonical), do: rename_latest_screenshot(name)

    session
  end

  defp rename_latest_screenshot(name) do
    case File.ls(@output_dir) do
      {:ok, files} ->
        latest =
          files
          |> Enum.filter(&String.ends_with?(&1, ".png"))
          |> Enum.map(&Path.join(@output_dir, &1))
          |> Enum.sort_by(&File.stat!(&1).mtime, :desc)
          |> List.first()

        if latest, do: File.rename!(latest, Path.join(@output_dir, "#{name}.png"))

      _ ->
        :ok
    end
  end

  defp configure_wallaby! do
    Application.put_env(:wallaby, :base_url, @base_url)
    Application.put_env(:wallaby, :screenshot_dir, @output_dir)
    Application.put_env(:wallaby, :screenshot_on_failure, false)
    Application.put_env(:wallaby, :driver, Wallaby.Chrome)

    chrome_options = %{
      binary: chrome_binary(),
      args: [
        "--headless=new",
        "--no-sandbox",
        "--disable-gpu",
        "--disable-dev-shm-usage",
        "--window-size=#{@window_size[:width]},#{@window_size[:height]}"
      ]
    }

    Application.put_env(:wallaby, :chromedriver,
      headless: true,
      binary: chrome_binary(),
      capabilities: %{chromeOptions: chrome_options}
    )
  end

  # Any Chromium-based browser works — auto-detect common installs, or
  # override with CHROME_BINARY=/path/to/binary.
  defp chrome_binary do
    System.get_env("CHROME_BINARY") ||
      Enum.find(
        [
          "/Applications/Helium.app/Contents/MacOS/Helium",
          "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
          "/Applications/Chromium.app/Contents/MacOS/Chromium",
          "/Applications/Arc.app/Contents/MacOS/Arc",
          "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
          "/usr/bin/chromium",
          "/usr/bin/google-chrome"
        ],
        &File.exists?/1
      ) ||
      Mix.raise("""
      No Chromium-based browser found. Install one of:
        brew install --cask helium          (or Chrome, Chromium, Arc, Brave)
      Or set CHROME_BINARY=/path/to/binary.
      """)
  end
end
