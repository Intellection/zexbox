defmodule Exbox.Metrics do
  alias Exbox.Metrics.MetricHandler

  def attach_controller_metrics(name) do
    attach_telemetry(name, [:phoenix, :endpoint, :stop])
  end

  def attach_telemetry(event, params) do
    :ok =
      :telemetry.attach(
        event,
        params,
        &MetricHandler.handle_event/4,
        nil
      )
  end
end
