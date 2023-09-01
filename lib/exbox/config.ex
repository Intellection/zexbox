defmodule Zexbox.Config do
  @moduledoc """
  Zexbox configuration module.
  All configurations have a default value, which can be overridden in the application config.
  The application config is keyed in the following way:
  ```elixir
  config :zexbox, :features, [
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

  @doc """
  Returns the configuration for capture_telemetry_metric_events
  """
  @spec capture_telemetry_metric_events? :: boolean()
  def capture_telemetry_metric_events?, do: config_value(:capture_telemetry_metric_events)

  @doc """
  Returns the configuration for capture_telemetry_log_events
  """
  @spec capture_telemetry_log_events? :: boolean()
  def capture_telemetry_log_events?, do: config_value(:capture_telemetry_log_events)

  @doc """
  Returns the configuration value for the given key.
  """
  @spec config_value(atom()) :: any()
  def config_value(key) do
    case Application.get_env(:zexbox, :features)[key] do
      nil -> Map.get(@default_config, key)
      value -> value
    end
  end
end
