defmodule AttachedDashboard.TestRepo do
  use Ecto.Repo,
    otp_app: :attached_dashboard,
    adapter: Ecto.Adapters.SQLite3
end
