defmodule Exbox.Metrics.Client do
  @moduledoc """
  Client for writing metrics to InfluxDB.
  """
  alias Exbox.Metrics.Connection
  require Logger

  @type series :: %Exbox.Metrics.Series.ControllerMetrics{}

  @doc """
  Write a metric to InfluxDB.
  """
  @spec write_metric(series()) :: tuple()
  def write_metric(metric) do
    if Application.get_env(:exbox, :capture_telemetry_events) do
      Connection.write(metric)
    end
  end
end
