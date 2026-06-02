defmodule AttachedDashboard.TestErrorHTML do
  def render("500.html", _), do: "Internal Server Error"
  def render("404.html", _), do: "Not Found"
end

Application.put_env(:attached_dashboard, AttachedDashboard.TestEndpoint,
  check_origin: false,
  live_view: [signing_salt: "attached_dashboard_test_salt!!"],
  render_errors: [formats: [html: AttachedDashboard.TestErrorHTML], layout: false],
  secret_key_base: String.duplicate("a", 64),
  server: false,
  url: [host: "localhost"]
)

defmodule AttachedDashboard.TestRouter do
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

defmodule AttachedDashboard.TestEndpoint do
  use Phoenix.Endpoint, otp_app: :attached_dashboard

  socket "/live", Phoenix.LiveView.Socket

  plug Plug.Session,
    store: :cookie,
    key: "_attached_dashboard_key",
    signing_salt: "attached!!"

  plug AttachedDashboard.TestRouter
end

ExUnit.start()

{:ok, _} = AttachedDashboard.TestRepo.start_link()
{:ok, _} = AttachedDashboard.TestEndpoint.start_link()

# Delegate the `attached_originals` / `attached_variants` schema to the lib's own
# migration — mirrors the pattern in `attached/test/support/migrations.ex`.
defmodule AttachedDashboard.TestMigrations do
  use Ecto.Migration

  def change do
    Oban.Migration.up(version: 12)
    Attached.Ecto.Migration.up()
  end
end

Ecto.Migrator.up(AttachedDashboard.TestRepo, 0, AttachedDashboard.TestMigrations, log: false)

sql = fn q -> Ecto.Adapters.SQL.query!(AttachedDashboard.TestRepo, q) end

# Minimal owner tables used by orphan-detection tests
sql.("""
  CREATE TABLE IF NOT EXISTS test_owners (
    id                           TEXT PRIMARY KEY,
    photo_attached_original_id   TEXT REFERENCES attached_originals(id),
    avatar_attached_original_id  TEXT REFERENCES attached_originals(id)
  )
""")

sql.("""
  CREATE TABLE IF NOT EXISTS other_owners (
    id                           TEXT PRIMARY KEY,
    cover_attached_original_id   TEXT REFERENCES attached_originals(id)
  )
""")

# Start Oban in manual testing mode for purge tests.
{:ok, _} =
  Oban.start_link(
    name: Oban,
    repo: AttachedDashboard.TestRepo,
    engine: Oban.Engines.Lite,
    testing: :manual,
    queues: false,
    plugins: false
  )
