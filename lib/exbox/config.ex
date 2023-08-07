defmodule Exbox.Config do
  @moduledoc """
  Exbox configuration module.
  This will find the configuration for the application and cache it in an Agent.
  All configurations have a default value, which can be overridden in the application config.
  The application config is keyed in the following way:
  ```elixir
  config :exbox, :features, [
    capture_telemetry_metric_events: true,
    capture_telemetry_log_events: false
  ]
  ```
  """
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: {:global, {:exbox, __MODULE__}})
  end

  @default_config %{
    capture_telemetry_metric_events: true,
    # default disabled until fully complete
    capture_telemetry_log_events: false
  }

  def capture_telemetry_metric_events?(), do: config_value(:capture_telemetry_metric_events)

  def capture_telemetry_log_events?(), do: config_value(:capture_telemetry_log_events)

  def config_value(key) do
    get_value_from_cache_or_fetch(key)
  end

  defp get_value_from_cache_or_fetch(key) do
    case get_state() do
      %{^key => value} ->
        value

      _ ->
        value = fetch_config(key)
        update_state(Map.put(get_state(), key, value))
        value
    end
  end

  defp get_state() do
    Agent.get({:global, {:exbox, __MODULE__}}, fn state -> state end)
  end

  defp fetch_config(key) do
    case Application.get_env(:exbox, :features)[key] do
      nil -> Map.get(@default_config, key)
      value -> value
    end
  end

  defp update_state(new_state) do
    Agent.update({:global, {:exbox, __MODULE__}}, fn _ -> new_state end)
  end
end
