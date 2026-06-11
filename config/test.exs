import Config

config :attached_dashboard, AttachedDashboard.TestRepo,
  database: ":memory:",
  pool_size: 1,
  log: false

config :attached,
  repo: AttachedDashboard.TestRepo,
  orphan_grace_period: 0

config :logger, level: :warning
