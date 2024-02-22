defmodule Zexbox.Logging do
  @moduledoc """
  This module is responsible for attaching logging to telemetry events.

  To use this module, you must have the Telemetry library installed.
  To do so, add {:telemetry, "~> 1.2.1"} to your list of dependencies in mix.exs.
  """
  alias Zexbox.Logging.LogHandler

  @doc """
  Attaches logging to the Phoenix endpoint stop and start events.
  By default will be attached on supervisor startup
  """
  @spec attach_controller_logs() :: :ok
  def attach_controller_logs do
    attach_telemetry(
      "phoenix_controller_logs_stop",
      [:phoenix, :endpoint, :stop],
      &LogHandler.handle_event/4
    )

    attach_telemetry(
      "phoenix_controller_logs_start",
      [:phoenix, :endpoint, :start],
      &LogHandler.handle_event/4
    )
  end

  @doc """
  Attaches logging to the given event with the given params.

  ## Examples
    ## Examples

  To attach metrics for a custom event `:my_event` with parameters `[:my, :event]`, and a custom handler function `my_handler/3`, you can do the following:

  ```elixir
  defmodule MyAppHandler do
    def my_handler(event, measurements, metadata) do
      # Your custom handler implementation here
    end
  end

  def start(_type, _args) do
    Zexbox.Logging.attach_telemetry(:my_event, [:my, :event], &MyAppHandler.my_handler/3)
  end
  ```
  In this example, when :my_event is triggered, the telemetry system will call MyAppHandler.my_handler/1 with the captured event data. Ensure that the handler function is implemented appropriately for your specific use case.

  Note: The logs will only be attached if the application environment variable :capture_telemetry_log_events is set to true.
  ## Parameters
    - `event` (binary()) - The name of the event to which metrics will be attached.
    - `params` (list(atom())) - A list of parameters representing the context of the event.
    - `function` (any(), any(), any(), any() -> any()) - The function to be called when the event occurs.
  Returns :ok if the logs are successfully attached.
  """
  @spec attach_telemetry(binary(), list(atom()), (any(), any(), any(), any() -> any())) :: :ok
  def attach_telemetry(event, params, function) do
    if Zexbox.Config.capture_telemetry_log_events?() do
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
