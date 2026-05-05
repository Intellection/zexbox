# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

### Added
- `Zexbox.Logging.JsonFormatter.config/1` (and the
  `Zexbox.Logging.json_formatter_config/1` delegate) — returns a
  `:logger` formatter tuple wrapping `LoggerJSON.Formatters.Basic` with
  Zappi-standard metadata and redactor defaults. Designed to be splatted
  into `config :logger, :default_handler, formatter: ...` in
  `runtime.exs`. Mirrors the Ruby-side opsbox `JsonFormatter` so Phoenix
  logs land in Elasticsearch as one structured document per event
  instead of fanning multi-line content out into many.

### Changed
- `:elixir` constraint bumped from `~> 1.14` to `~> 1.15` to match the
  `logger_json` 7.x requirement.

### Dependencies
- Adds `logger_json ~> 7.0`.

### Notes
- This release does not pin `:jason`. Consumers may include it directly
  (the default `LoggerJSON` encoder) or, on Elixir 1.18+, set
  `config :logger_json, encoder: JSON` to use the stdlib `JSON` module.

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
