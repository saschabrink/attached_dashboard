# AttachedDashboard

Phoenix LiveView dashboard for the [`attached`](https://hex.pm/packages/attached) file-attachment library.

- Browse and filter all uploaded originals and their variants
- Inspect metadata, previews, and owner records per file
- Purge files individually, in bulk, or by owner group
- Re-trigger metadata extraction on demand
- Find and clean up orphaned originals whose owner record is gone
- View configured processors (extractors, transformers, previewers) with runtime availability

## Screenshots

A short tour. Click any image for the full-resolution file.

[![Overview](docs/screenshots/overview.png)](docs/screenshots/overview.png)

*Overview — KPIs (originals, variants, orphans, total size), content-type distribution, storage usage, recent uploads.*

---

[![Originals](docs/screenshots/originals_index.png)](docs/screenshots/originals_index.png)

*Originals — browse every original with filters (kind, content type, storage backend, owner table/field) and sorting. See [variants view](docs/screenshots/variants_index.png) for the Variants pill.*

---

[![Original detail](docs/screenshots/originals_show.png)](docs/screenshots/originals_show.png)

*Original detail — metadata, owner link, variants derived from this original. Variant pages show an [origin banner](docs/screenshots/variants_show.png) linking back to the source.*

---

[![Owners](docs/screenshots/owners_index.png)](docs/screenshots/owners_index.png)

*Owners — every `(owner_table, owner_field)` group with original counts, sizes, and a "browse" link that carries the filter into the originals view.*

---

[![Processors](docs/screenshots/processors_index.png)](docs/screenshots/processors_index.png)

*Processors — configured metadata extractors, previewers, and transformers with runtime availability and install hints. Doubles as an install checklist.*

---

[![Orphans](docs/screenshots/orphans_index.png)](docs/screenshots/orphans_index.png)

*Orphans — originals whose owner record is gone. Purge selectively, per group, or everything at once.*

## Installation

```elixir
def deps do
  [{:attached_dashboard, "~> 0.1"}]
end
```

## Usage

```elixir
# router.ex
import AttachedDashboard.Router

scope "/" do
  pipe_through :browser
  attached_dashboard "/admin/files"
end
```

Visit `/admin/files` to open the dashboard.

### Access control

The dashboard has no built-in auth — protect it in your router. Two common patterns:

**Quick: HTTP Basic Auth**

```elixir
# router.ex
import Plug.BasicAuth, only: [basic_auth: 2]

pipeline :dashboard_auth do
  plug :basic_auth, username: "admin", password: System.fetch_env!("DASHBOARD_PASSWORD")
end

scope "/" do
  pipe_through [:browser, :dashboard_auth]
  attached_dashboard "/admin/files"
end
```

**Proper: hook into your existing auth via `:on_mount`**

```elixir
scope "/" do
  pipe_through [:browser, :require_admin]
  attached_dashboard "/admin/files", on_mount: [{MyAppWeb.UserAuth, :ensure_authenticated}]
end
```

`:on_mount` hooks run inside the dashboard's `live_session`, so LiveView navigation
stays protected too — not just the initial HTTP request.

## License

MIT
