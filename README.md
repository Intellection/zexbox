# Zexbox

[![Hex.pm](https://img.shields.io/hexpm/v/zexbox.svg)](https://hex.pm/packages/zexbox)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/Intellection/zexbox/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/Intellection/zexbox/tree/master)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/zexbox/api-reference.html)

## Installation

The can be installed by adding `zexbox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zexbox, "~> 0.5.0"}
  ]
end
```

## Configuration
### LaunchDarkly Feature Flags
```
config :zexbox, :flags,
  sdk_key: "dev-launch-darkly-key",
  file_datasource: true,
  send_events: false,
  file_auto_update: true,
  file_poll_interval: 1000,
  feature_store: :ldclient_storage_map,
  file_paths: ["flags.json"]
```

### Influx Metrics
```
config :zexbox, Zexbox.Metrics.Connection,
  host: "localhost:8086",
  auth: [
    method: :token,
    token: "token"
  ],
  bucket: "my_app",
  org: "zappi",
  version: :v2
```

### Telemetry
```
  config :zexbox, :features,
    capture_telemetry_metric_events: true,
    capture_telemetry_log_events: true
```

## Docker Compose

- Run

```
docker compose up
```

- For grafana browse to `http://localhost:3000/`
- use `http://influxdb:8086` as a data source

## Copyright and License

Copyright (c) 2023, Zappistore.

Zexbox source code is licensed under the [MIT License](LICENSE.md).
