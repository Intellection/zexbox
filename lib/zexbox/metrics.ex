defmodule Zexbox.Metrics do
  @moduledoc """
  A module for handling and standardising metrics in Zexbox applications.

  If you want to attach metrics to other events, you can use `Zexbox.Metrics.attach_telemetry/3`:

  ## Examples

  ```elixir
  def start(_type, _args) do
    Zexbox.Metrics.attach_telemetry(:my_event, [:my, :params], &my_handler/1)
  end
  ```

  ## Public API

  The following functions are provided by this module:

  - `attach_controller_metrics/0`: Attaches metrics to the Phoenix endpoint stop event.
  - `attach_telemetry/3`: Attaches metrics to the given event with the given params.
  """

  alias Zexbox.Metrics.MetricHandler

  @doc """
  Attaches metrics to the Phoenix endpoint stop event.

  ## Examples

      iex> Zexbox.Metrics.attach_controller_metrics()
      :ok

  """
  @spec attach_controller_metrics() :: :ok
  def attach_controller_metrics do
    attach_telemetry(
      "phoenix_controller_metrics",
      [:phoenix, :endpoint, :stop],
      &MetricHandler.handle_event/4
    )
  end

  @doc """
  Attaches metrics to the given event with the given params.

  Note: The metrics will only be attached if the application environment variable :capture_telemetry_events is set to true.

  ## Examples

      iex> Zexbox.Metrics.attach_telemetry(:my_event, [:my, :event], &MyAppHandler.my_handler/3)
      :ok

  """
  @spec attach_telemetry(
          event_name :: binary(),
          event_params :: [atom() | :stop],
          callback :: (any(), any(), any(), any() -> any())
        ) :: :ok
  def attach_telemetry(event, params, function) do
    if Zexbox.Config.capture_telemetry_metric_events?() do
      :ok =
        :telemetry.attach(
          event,
          params,
          function,
          nil
        )
    end
  end
end
