import Config

config :attached_dashboard, AttachedDashboard.Screenshots.Repo,
  database: ":memory:",
  pool_size: 1,
  log: false

config :attached, repo: AttachedDashboard.Screenshots.Repo
