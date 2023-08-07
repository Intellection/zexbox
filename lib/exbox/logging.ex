defmodule Exbox.Logging do
  alias Exbox.Logging.LogHandler

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

  @spec attach_telemetry(binary(), list(atom()), (any() -> any())) :: :ok
  def attach_telemetry(event, params, function) do
    if Exbox.Config.capture_telemetry_log_events?() do
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
