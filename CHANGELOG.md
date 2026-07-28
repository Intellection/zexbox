# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

- Override `hackney` to `~> 4.0`, resolving the open `hackney` 1.x security advisories (`ssl:connect/2` handshake timeout, CR/LF query injection, header injection, SSRF allowlist bypass) that instream pins transitively. **Consuming applications must add `{:hackney, "~> 4.0", override: true}` to their own top-level deps** — Mix ignores `:override` in nested dependencies, so once this ships, apps on the old resolution will hit a dependency-divergence error until they add the override. Removes the `--ignore-package-names hackney` workaround from the `audit` alias.

## 1.6.0 - 2026-07-23

- Add `requester` field to `Zexbox.Metrics.ControllerSeries` (not populated by default).
- Add `Zexbox.Metrics.ControllerSeriesEnricher` behaviour and an `:enricher` option on `Zexbox.Metrics.start_link/1` (also configurable via `config :zexbox, :metrics_enricher`) for setting tags/fields on the controller series from the `conn` before it is written.

## 1.5.1 - 2026-02-05

- Handles cases where `$callers` and `$ancestors` may not be pids to avoid crashing metric handler.

## 1.5.0 - 2026-02-04

- Move CI from Circle to Github Actions
- Add the ability to disable metrics for a process. This applies to all child processes started with the `$caller` being set, so will not propogate to child processes spawned with the `spawn` function.

## [1.4.1] - 2024-12-04

- Update dependencies

## [1.4.0] - 2024-12-04

- Update dependencies

## [1.3.0] - 2024-10-15

- Initial public release
