# Zexbox

[![Hex.pm](https://img.shields.io/hexpm/v/zexbox.svg)](https://hex.pm/packages/zexbox)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/Intellection/zexbox/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/Intellection/zexbox/tree/master)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/zexbox/api-reference.html)

## Installation

The can be installed by adding `zexbox` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:zexbox, "~> 0.6.0"}
  ]
end
```

## LaunchDarkly Feature Flags

### Configuration

Configuration is fairly simple, with the only required piece of configuration being the `sdk_key`. For production environments we recommend also including `:email` as a private attribute:

```elixir
config :zexbox, :flags,
  sdk_key: System.fetch_env!("LAUNCH_DARKLY_SDK_KEY"),
  private_attributes: [:email]
```

For local development and testing you'll probably want to [read flags from a local file](https://docs.launchdarkly.com/sdk/features/flags-from-files) and ensure there is no interaction with this API. While the two configurations will be very similar you should have different ones to put to different files. You're configurations will look something like this following:

```elixir
config :zexbox, :flags,
  sdk_key: "dev-launch-darkly-key",
  file_datasource: true,
  send_events: false,
  file_auto_update: true,
  file_poll_interval: 1000,
  feature_store: :ldclient_storage_map,
  file_paths: ["flags.json"]
```

### Implementing

In order to use feature flags you need to start the LaunchDarkly client using. You should do this in the `start/2` function of your `Application` module:

```elixir
def start(_type, _args) do
  Zexbox.Flags.start()
  ...
end
```

You should laso make sure that the client shuts down when your app does in the `stop/2` function of your `Application` module:

```elixir
def stop(_type, _args) do
  Zexbox.Flags.stop()
  ...
end
```

Evaluating a flag can be achieved by simply calling the `variation/3` function.

```elixir
Zexbox.Flags.variation(
  "my-flag",
  %{key: "user-hash", email: "user@email.com"},
  "my_default_value"
)
```

## Metrics and Logging

### Configuration

In order to setup metrics with InfluxDB you'll need to add the following configuration

```elixir
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

By default both metrics and logging will be enabled, you can customise this with the following configuration

```elixir
config :zexbox, :features,
  capture_telemetry_metric_events: true,
  capture_telemetry_log_events: true
```

### Implementing

In order to make use of metrics and logging you'll need to add the `Zexbox` module to your application's `Supervisor` tree

```elixir
defmodule MyApp.Application do
  use Application

  @impl Application
  def start(_type, args) do
    ...
    children = [
      ...
      {Zexbox, []}
    ]
    ...
    Supervisor.start_link(children, opts)
  end
end
```

This will attach the telemetry and logging events to your controllers (assuming that they are enable in the `:features` config)

## Copyright and License

Copyright (c) 2024, Zappistore.

Zexbox source code is licensed under the [MIT License](LICENSE.md).
