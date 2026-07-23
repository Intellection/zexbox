# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
