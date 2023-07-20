defmodule Exbox.Metrics do
  alias Exbox.Metrics.MetricHandler

  @spec attach_controller_metrics(binary()) :: :ok
  def attach_controller_metrics(name) do
    attach_telemetry(name, [:phoenix, :endpoint, :stop])
  end

  @spec attach_telemetry(binary(), list(atom())) :: :ok
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
