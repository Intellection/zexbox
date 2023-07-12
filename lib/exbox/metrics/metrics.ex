defmodule Exbox.Metrics do
  alias Exbox.Metrics.MetricHandler

  def attach_telemetry(false), do: :ok

  def attach_telemetry(true) do
    :ok =
      :telemetry.attach(
        "#{Application.fetch_env!(:exbox, :metrics_app)}_endpoint_stop",
        [:phoenix, :endpoint, :stop],
        &MetricHandler.handle_event/4,
        nil
      )
  end
end
