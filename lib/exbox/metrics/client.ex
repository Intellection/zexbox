defmodule Exbox.Metrics.Client do
  @moduledoc """
  A client module for writing metrics to InfluxDB.

  ## Overview

  This module provides functions to write metrics to InfluxDB, a time-series database that allows for efficient storage and querying of data with a timestamp.

  To use this module, you need to have the `Exbox.Metrics.Connection` application running. Make sure to start it as an application in your supervision tree:

  ```elixir
  def start(_type, _args) do
    children = [
      {Exbox.Metrics.Connection, []}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
  ```

  ## Writing Metrics
    The main function provided by this module is write_metric/1. It accepts a metric data structure and writes it to InfluxDB.

  ## Examples

  ## Writing Custom metrics

    ```elixir
    iex> metric = %Exbox.Metrics.Series.Generic{
    ...>   measurement: "my_measurement",
    ...>   fields: %{
    ...>     "my_field" => 1
    ...>   },
    ...>   tags: %{
    ...>     "my_tag" => "my_value"
    ...>   }
    ...> }
    iex> Exbox.Metrics.Client.write_metric(metric)
    {:ok, %Exbox.Metrics.Series.Generic{
      measurement: "my_measurement",
      fields: %{
        "my_field" => 1
      },
      tags: %{
        "my_tag" => "my_value"
      }
    }}
    ```

    ### Error Handling
    If there is an error while writing the metric, the function will log the error using the Logger module. without crashing the process
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
  def write_metric(%Exbox.Metrics.Series.Generic{} = metrics) do
    metrics
    |> Map.from_struct()
    |> write_to_influx()
  end

  def write_metric(metrics), do: write_to_influx(metrics)

  defp write_to_influx(metrics) do
    try do
      metrics
      |> Connection.write()
    rescue
      error ->
        Logger.debug("Failed to write metric to InfluxDB: #{inspect(error)}")
    end
  end
end
