# Changelog

## [0.2.2] - 2026-06-12

### Changed
- CI tests against Elixir 1.19 and 1.20 via the Nix flake dev shells.
- README badges for CI status and license, alongside the existing
  hex/hexdocs pair.

## [0.2.1] - 2026-06-11

### Documentation

- README: fixed the router import in the usage example —
  `AttachedDashboard.Router` → `AttachedDashboard.Web.Router` (the old
  module doesn't exist, so the copy-pasted snippet failed to compile).
- README: hex/hexdocs badges, install version bumped to `~> 0.2` with an
  `attached` version-pairing note, link to the
  [demo app](https://github.com/saschabrink/attached_phoenix_demo), and
  screenshots switched to absolute URLs so they render on hex.pm and
  hexdocs, not just on GitHub.

## [0.2.0] - 2026-06-11

### Changed — BREAKING

- Requires `attached ~> 0.2`. Storage backends are now named instances in a
  registry; the `storage_backend` column on `attached_originals` records the
  instance name (e.g. `"local"`, `"s3_main"`) instead of the module name.
  The OverviewPage service-breakdown panel and the originals filter display
  whatever name the running app has configured.

### Fixed

- Orphan-purge tests now set `config :attached, orphan_grace_period: 0` so
  freshly-created test orphans are not skipped by the new 48 h grace period
  introduced in `attached 0.2.0`.
- `Oban.start_link` in the test helper now passes `notifier: Oban.Notifiers.PG`
  to avoid an `ArgumentError` from Oban 2.23, which validates that the notifier
  module is loaded (the old default `Oban.Notifiers.Postgres` requires
  `postgrex`, unavailable in the SQLite test setup).

## [0.1.0] - 2026-06-08

### Added

- `attached_dashboard/2` router macro for mounting the dashboard
- `AttachedDashboard.Resolver` behaviour for access control and refresh rate
- OverviewPage — original/variant/orphan stats, service breakdown, recent activity
- OriginalsPage — filterable, sortable, paginated originals table with bulk actions
- OriginalShowPage — metadata, preview, variants, owner lookup, purge/re-analyze actions
- OrphansPage — orphan scan grouped by owner, purge-group and purge-all actions
- VariantsPage — variant records table with per-row purge action
- Telemetry events for all state-changing dashboard actions


