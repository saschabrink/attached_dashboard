defmodule AttachedDashboard.Web.Mounts.SessionMount do
  @moduledoc false

  import Phoenix.Component, only: [assign: 2]

  @doc false
  def on_mount(:default, _params, session, socket) do
    csp_nonces = Map.get(session, "csp_nonces", %{img: nil, style: nil, script: nil})

    socket =
      assign(socket,
        csp_nonces: csp_nonces,
        prefix: session["prefix"],
        backlink: session["backlink"]
      )

    {:cont, socket}
  end
end
