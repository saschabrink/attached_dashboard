import Config

config :attached_dashboard, AttachedDashboard.TestRepo,
  database: ":memory:",
  pool_size: 1,
  log: false

config :attached, repo: AttachedDashboard.TestRepo

config :logger, level: :warning
