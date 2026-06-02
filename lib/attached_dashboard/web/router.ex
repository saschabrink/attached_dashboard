defmodule AttachedDashboard.Web.Router do
  @moduledoc """
  Phoenix router for the AttachedDashboard.

  Also provides the `attached_dashboard/1,2` macro that host apps use to mount
  the dashboard at a chosen prefix.

  ## Usage

      # router.ex
      import AttachedDashboard.Web.Router

      scope "/" do
        pipe_through :browser
        attached_dashboard "/admin/files"
      end

  ## Options

  * `:on_mount` — `on_mount` hooks added to the dashboard's `live_session`. Use this to
    enforce authentication from the host app.
  * `:as` — override the route helper name. Defaults to `:attached_dashboard`.
  * `:csp_nonce_assign_key` — CSP nonce key (atom or map with `:img`, `:style`, `:script` keys).
  * `:backlink` — path in the host app to return to from the dashboard sidebar
    (e.g. `"/admin"`). When set, the sidebar title becomes a link to this path.
    Use a full URL/path string; the target lives outside the dashboard's
    `live_session`, so navigation is a regular request (full page reload).
  """

  use Phoenix.Router
  import Phoenix.LiveView.Router

  # Actual routes — single source of truth. Used for:
  #   1. `~p` compile-time path validation via Phoenix.VerifiedRoutes
  #   2. The `attached_dashboard/1,2` mount macro below, which re-emits these
  #      routes scoped under the host app's chosen prefix.
  live "/", AttachedDashboard.Web.Live.OverviewLive, :index
  live "/originals", AttachedDashboard.Web.Live.Originals.IndexLive, :index
  live "/originals/:id", AttachedDashboard.Web.Live.Originals.ShowLive, :show
  live "/originals/:original_id/variants/:id", AttachedDashboard.Web.Live.Originals.Variants.ShowLive, :show
  live "/variants", AttachedDashboard.Web.Live.Variants.IndexLive, :index
  live "/orphans", AttachedDashboard.Web.Live.Orphans.IndexLive, :index
  live "/orphans/:owner_table/:owner_field", AttachedDashboard.Web.Live.Orphans.ShowLive, :show
  live "/owners", AttachedDashboard.Web.Live.Owners.IndexLive, :index
  live "/processors", AttachedDashboard.Web.Live.Processors.IndexLive, :index

  @doc """
  Mounts the AttachedDashboard at the given path in the host app's router.
  """
  defmacro attached_dashboard(path, opts \\ []) do
    opts =
      if Macro.quoted_literal?(opts) do
        Macro.prewalk(opts, &expand_alias(&1, __CALLER__))
      else
        opts
      end

    live_routes =
      for route <- __MODULE__.__routes__(),
          lv = route.metadata[:phoenix_live_view],
          match?({_, _, _, _}, lv) do
        {module, action, _opts, _live_session} = lv
        {route.path, module, action}
      end

    route_quotes =
      for {rpath, module, action} <- live_routes do
        quote do
          live unquote(rpath), unquote(module), unquote(action), route_opts
        end
      end

    quote do
      scope unquote(path), alias: false, as: false do
        import Phoenix.LiveView.Router, only: [live: 4, live_session: 3]

        {session_name, session_opts, route_opts} =
          AttachedDashboard.Web.Router.__options__(unquote(path), unquote(opts))

        live_session session_name, session_opts do
          (unquote_splicing(route_quotes))
        end

        get "/*filename", AttachedDashboard.Web.Controllers.AssetsController, :asset, as: :attached_dashboard_asset
      end
    end
  end

  defp expand_alias({:__aliases__, _, _} = alias, env) do
    Macro.expand(alias, %{env | function: {:attached_dashboard, 2}})
  end

  defp expand_alias(other, _env), do: other

  @doc false
  def __options__(prefix, opts) do
    as = Keyword.get(opts, :as, :attached_dashboard)
    csp_key = Keyword.get(opts, :csp_nonce_assign_key)
    backlink = Keyword.get(opts, :backlink)
    on_mount = Keyword.get(opts, :on_mount, []) ++ [AttachedDashboard.Web.Mounts.SessionMount]

    session_opts = [
      on_mount: on_mount,
      session: {__MODULE__, :__session__, [prefix, csp_key, backlink]},
      root_layout: {AttachedDashboard.Web.Components.Layouts, :root},
      layout: false
    ]

    {as, session_opts, [as: as]}
  end

  @doc false
  def __session__(conn, prefix, csp_key, backlink) do
    %{
      "prefix" => prefix,
      "backlink" => backlink,
      "csp_nonces" => expand_csp_nonces(conn, csp_key)
    }
  end

  defp expand_csp_nonces(_conn, nil), do: %{img: nil, style: nil, script: nil}

  defp expand_csp_nonces(conn, key) when is_atom(key) do
    nonce = conn.assigns[key]
    %{img: nonce, style: nonce, script: nonce}
  end

  defp expand_csp_nonces(conn, map) when is_map(map) do
    %{
      img: conn.assigns[map[:img]],
      style: conn.assigns[map[:style]],
      script: conn.assigns[map[:script]]
    }
  end
end
