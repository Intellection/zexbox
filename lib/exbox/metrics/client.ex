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
  def write_metric(metric = %Exbox.Metrics.Series.Generic{}) do
    metric
    |> Map.from_struct()
    |> write_to_influx()
  end

  @spec write_metric(series()) :: tuple()
  def write_metric(metric), do: write_to_influx(metric)

  defp write_to_influx(metric) do
    try do
      metric
      |> Connection.write()
    rescue
      error ->
        Logger.debug("Failed to write metric to InfluxDB: #{inspect(error)}")
    end
  end
end
