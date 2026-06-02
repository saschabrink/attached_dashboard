defmodule AttachedDashboard do
  @moduledoc """
  Phoenix LiveView dashboard for the `attached` file-attachment library.

  Provides a mounted dashboard for inspecting originals, variants, and orphans
  in a running application.

  ## Setup

  Add the router macro to your application's router:

      # router.ex
      import AttachedDashboard.Web.Router

      scope "/" do
        pipe_through :browser
        attached_dashboard "/admin/files"
      end

  ## Authentication

  The dashboard does not handle authentication itself. Mount it inside a
  `live_session` with your own `on_mount` hook, or pass `:on_mount` directly:

      attached_dashboard "/admin/files", on_mount: MyApp.RequireAdmin

  Your `on_mount` hook can halt and redirect unauthenticated users as usual:

      def on_mount(:default, _params, session, socket) do
        if session["current_user_admin?"] do
          {:cont, socket}
        else
          {:halt, Phoenix.LiveView.redirect(socket, to: "/login")}
        end
      end

  ## Options

  * `:on_mount` — `on_mount` hooks added to the dashboard's `live_session`.
  * `:as` — override the route name; defaults to `:attached_dashboard`.
  * `:csp_nonce_assign_key` — CSP nonce key (atom or map) pulled from conn assigns.
  """
end
