defmodule AttachedDashboard.Web.RouterTest do
  use ExUnit.Case, async: true

  alias AttachedDashboard.Web.Router

  describe "__options__/2 :backlink" do
    test "defaults to nil when not provided" do
      {_as, session_opts, _route_opts} = Router.__options__("/files", [])
      {mod, fun, args} = session_opts[:session]

      assert {Router, :__session__} == {mod, fun}
      # session args: [prefix, csp_key, backlink]
      assert List.last(args) == nil
    end

    test "is forwarded into session args when set" do
      {_as, session_opts, _route_opts} =
        Router.__options__("/files", backlink: "/admin")

      {_mod, _fun, args} = session_opts[:session]
      assert List.last(args) == "/admin"
    end

    test "ends up under \"backlink\" in the session map" do
      session = Router.__session__(%Plug.Conn{assigns: %{}}, "/files", nil, "/admin")
      assert session["backlink"] == "/admin"
      assert session["prefix"] == "/files"
    end
  end
end
