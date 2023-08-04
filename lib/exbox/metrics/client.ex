defmodule Exbox.Metrics.Client do
  @moduledoc """
  Client for writing metrics to InfluxDB.
  """
  alias Exbox.Metrics.Connection
  require Logger

  @type series :: %Exbox.Metrics.Series.ControllerMetrics{}

  @doc """
  Write a metric to InfluxDB.

  Examples:

      iex> Exbox.Metrics.Client.write_metric(%ControllerMetrics{})
      {:ok, %ControllerMetrics{}}
  """
  @spec write_metric(series()) :: tuple()
  def write_metric(metric) do
    try do
      Connection.write(metric)
    rescue
      error ->
        Logger.debug("Failed to write metric to InfluxDB: #{inspect(error)}")
    end
  end
end
