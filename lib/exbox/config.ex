defmodule Exbox.Config do
  @moduledoc """
  Exbox configuration module.
  All configurations have a default value, which can be overridden in the application config.
  The application config is keyed in the following way:
  ```elixir
  config :exbox, :features, [
    capture_telemetry_events: true,
    dummy_flag: false
  ]
  ```
  """

  @default_config %{
    capture_telemetry_events: true,
    dummy_flag: false
  }

  def capture_telemetry_events?(), do: config_value(:capture_telemetry_events)

  def dummy_flag?(), do: config_value(:dummy_flag)

  def config_value(key) do
    case Application.get_env(:exbox, :features)[key] do
      nil -> Map.get(@default_config, key)
      value -> value
    end
  end
end
