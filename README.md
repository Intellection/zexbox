# Zexbox

[![Hex.pm](https://img.shields.io/hexpm/v/zexbox.svg)](https://hex.pm/packages/zexbox)
[![CircleCI](https://dl.circleci.com/status-badge/img/gh/Intellection/zexbox/tree/master.svg?style=shield)](https://dl.circleci.com/status-badge/redirect/gh/Intellection/zexbox/tree/master)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/zexbox/api-reference.html)

## Installation

```elixir
def deps do
  [
    {:zexbox, "~> 1.4.1"}
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

For local development and testing you'll probably want to [read flags from a local file](https://docs.launchdarkly.com/sdk/features/flags-from-files) and ensure there is no interaction with the LaunchDarkly API. While the two configurations will be very similar you should have different ones to put to different files. You're configurations will look something like this following:

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

In order to use feature flags you need to start the LaunchDarkly client. You should do this in the `start/2` function of your `Application` module:

```elixir
def start(_type, _args) do
  Zexbox.Flags.start()
  ...
end
```

This will initialise a LauncDarkly client with the `:default` tag and using the configuration you've defined in your app.

If you wish to use a different tag you can make use of `Zexbox.Flags.start/1`

```elixir
Zexbox.Flags.start(:my_tag)
```

Additionally, if you don't want to make use of the application config you can use `Zexbox.Flags.start/2`

```elixir
Zexbox.Flags.start(
  %{
    sdk_key: "my-sdk-key", # This key is required
    private_attributes: [:email]
  },
  :my_tag
)
```

You can then shut the `:default` client down when your app does in the `Zexbox.Flags.stop/0` function of your `Application` module:

```elixir
def stop(_type, _args) do
  Zexbox.Flags.stop()
end
```

Stopping a client with a custom tag can be done using the `Zexbox.Flags.stop/1` function.

Evaluating a flag can be achieved by simply calling the `Zexbox.Flags.variation/3` function.

```elixir
Zexbox.Flags.variation(
  "my-flag",
  %{key: "user-hash", email: "user@email.com"},
  "my_default_value"
)
```

## Logging

Default logging can be attached to your controllers by calling `Zexbox.Logging.attach_controller_logs!` in the `start/2` function of your `Application` module:

```elixir
def start(_type, _args) do
  Zexbox.Logging.attach_controller_logs!()
  ...
end
```

This sets up handlers for the `[:phoenix, :endpoint, :start]` and `[:phoenix, :endpoint, :stop]` [events](https://hexdocs.pm/phoenix/1.4.12/Phoenix.Endpoint.html#module-instrumentation) which are dispatched by `Plug.Telemetry` at the beginning and end of each request. The handlers are named `phoenix_controller_logs_stop` and `phoenix_controller_logs_start` respectively. The handlers log structured data (reports) in the following form `[info] [event: <event_params>, measurements: <measurement_data>, metadata: <metadat>, config: <config>]`.

### Adding your own logs

Adding your own logs is as simple as calling the `Zexbox.Telementry.attach/4` (which is just a wrapper around `:telemetry.attach/4`)

```elixir
Zexbox.Telemetry.attach(:my_event, [:my, :event], &MyAppHandler.my_handler/3, nil)
```

## Metrics

In order to setup metrics with InfluxDB you'll need to add the following configuration:

```elixir
config :zexbox, Zexbox.Metrics.Connection,
  auth: [
    method: :token,
    token: "token"
  ],
  host: "localhost",
  port: "8086",
  version: :v2,
  org: "zappi",
  bucket: "my_app"
```

A more indepth explanation on the configuration can be found in the `Instream.Connection` [hexdocs](https://hexdocs.pm/instream/Instream.html).

In order to make use of metrics you'll need to add the `Zexbox` module to your application's `Supervisor` tree

```elixir
defmodule MyApp.Application do
  use Application

  @impl Application
  def start(_type, args) do
    ...
    children = [
      ...
      {Zexbox.Metrics, []}
    ]
    ...
    Supervisor.start_link(children, opts)
  end
end
```

This will write metrics to InfluxDB after every Phoenix DB request. The structure of the metrics is defined by the  `Zexbox.Metrics.ControllerSeries` module.

### Adding Custom Controller Metrics

You can easily add your own controller metrics using the `Zexbox.Metrics.Client` module

```elixir
metric = %Zexbox.Metrics.Series{
  measurement: "my_measurement",
  fields: %{
    "my_field" => 1
  },
  tags: %{
    "my_tag" => "my_value"
  }
}
Zexbox.Metrics.Client.write_metric(metric)
```

### Disabling Metrics For a Single Request/Process

If you want to suppress metrics for a specific request (for example: test traffic, synthetic checks, or health probes), disable metrics for the **current process**:

```elixir
Zexbox.Metrics.disable_for_process()
```

All metric writes from that process will be skipped (including the default controller metrics and any custom calls to `Zexbox.Metrics.Client.write_metric/1`). If you spawn tasks using `Task.async/1`, the disabled state is also respected in the spawned task via the caller chain.

To re-enable metrics for the current process:

```elixir
Zexbox.Metrics.enable_for_process()
```

## Copyright and License

Copyright (c) 2024, Zappistore.

Zexbox source code is licensed under the [MIT License](LICENSE.md).
