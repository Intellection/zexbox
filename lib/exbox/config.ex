defmodule Exbox.Config do
  @moduledoc """
  Exbox configuration module.
  All configurations have a default value, which can be overridden in the application config.
  The application config is keyed in the following way:
  ```elixir
  config :exbox, :features, [
    capture_telemetry_metric_events: true,
    capture_telemetry_log_events: false
  ]
  ```
  """

  @default_config %{
    capture_telemetry_metric_events: true,
    # default disabled until fully complete
    capture_telemetry_log_events: false
  }

  def capture_telemetry_metric_events?(), do: config_value(:capture_telemetry_metric_events)

  def capture_telemetry_log_events?(), do: config_value(:capture_telemetry_log_events)

  def config_value(key) do
    case Application.get_env(:exbox, :features)[key] do
      nil -> Map.get(@default_config, key)
      value -> value
    end
  end
end
