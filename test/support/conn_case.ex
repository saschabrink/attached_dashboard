defmodule AttachedDashboard.ConnCase do
  @moduledoc "Sets up a Phoenix conn for controller and LiveView tests."

  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest

      alias AttachedDashboard.TestRouter

      @endpoint AttachedDashboard.TestEndpoint
    end
  end

  setup _tags do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
