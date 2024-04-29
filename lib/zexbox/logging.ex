defmodule Zexbox.Logging do
  @moduledoc """
  This module is responsible for attaching logging to telemetry events.
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

  Note: The logs will only be attached if the application environment variable :capture_telemetry_log_events is set to true.

  ## Examples

      iex> Zexbox.Logging.attach_telemetry(:my_event, [:my, :event], &MyAppHandler.my_handler/3)
      :ok

  """
  @spec attach_telemetry(
          event_name :: binary(),
          event_params :: list(atom()),
          callback :: (any(), any(), any(), any() -> any())
        ) :: :ok
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
