defmodule AttachedDashboard.DataCase do
  @moduledoc """
  Case template for tests that hit the in-memory SQLite database.

  Uses `async: false` — pool_size: 1 with `:memory:` cannot be shared across
  concurrent test processes. Tables are truncated before each test so every
  test starts with a clean slate.
  """

  use ExUnit.CaseTemplate

  alias AttachedDashboard.TestRepo

  using do
    quote do
      use ExUnit.Case, async: false
      alias AttachedDashboard.TestRepo
      alias AttachedDashboard.Test.Factory
      import Ecto.Query
    end
  end

  setup do
    Ecto.Adapters.SQL.query!(TestRepo, "DELETE FROM test_owners")
    TestRepo.delete_all(Attached.Variants.Variant)
    TestRepo.delete_all(Attached.Originals.Original)
    :ok
  end
end
