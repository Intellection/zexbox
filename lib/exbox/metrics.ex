defmodule Zexbox.Metrics do
  @moduledoc """
  A module for handling and standardising metrics in Zexbox applications.

  To use this module, you must have the Telemetry library installed.
  To do so, add {:telemetry, "~> 1.2.1"} to your list of dependencies in mix.exs.

  If you want to attach metrics to other events, you can use `Zexbox.Metrics.attach_telemetry/3`:

  ## Examples

      def start(_type, _args) do
        Zexbox.Metrics.attach_telemetry(:my_event, [:my, :params], &my_handler/1)
      end

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

  ## Examples

  To attach metrics for a custom event `:my_event` with parameters `[:my, :event]`, and a custom handler function `my_handler/3`, you can do the following:

  ```elixir
  defmodule MyAppHandler do
    def my_handler(event, measurements, metadata) do
      # Your custom handler implementation here
    end
  end

  def start(_type, _args) do
    Zexbox.Metrics.attach_telemetry(:my_event, [:my, :event], &MyAppHandler.my_handler/3)
  end
  ```
  In this example, when :my_event is triggered, the telemetry system will call MyAppHandler.my_handler/1 with the captured event data. Ensure that the handler function is implemented appropriately for your specific use case.

  Note: The metrics will only be attached if the application environment variable :capture_telemetry_events is set to true.
  ## Parameters
    - `event` (binary()) - The name of the event to which metrics will be attached.
    - `params` (list(atom())) - A list of parameters representing the context of the event.
    - `function` (any(), any(), any(), any() -> any()) - The function to be called when the event occurs.
  Returns :ok if the metrics are successfully attached.
  """
  @spec attach_telemetry(binary(), [atom() | :stop], (any(), any(), any(), any() -> any())) :: :ok
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
