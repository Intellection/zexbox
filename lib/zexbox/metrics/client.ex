defmodule Zexbox.Metrics.Client do
  @moduledoc """
  A client module for writing metrics to InfluxDB.

  ## Overview

  This module provides functions to write metrics to InfluxDB, a time-series database that allows for efficient storage and querying of data with a timestamp.

  To use this module, you need to have the `Zexbox.Metrics.Connection` application running. Make sure to start it as an application in your supervision tree:

  ```elixir
  def start(_type, _args) do
    children = [
      {Zexbox.Metrics.Connection, []}
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
  ```

  ## Writing Metrics
  The main function provided by this module is write_metric/1. It accepts a metric data structure and writes it to InfluxDB.

  ## Examples

  ### Writing Custom metrics

  ```elixir
  iex> metric = %Zexbox.Metrics.Series.Generic{
  ...>   measurement: "my_measurement",
  ...>   fields: %{
  ...>     "my_field" => 1
  ...>   },
  ...>   tags: %{
  ...>     "my_tag" => "my_value"
  ...>   }
  ...> }
  iex> Zexbox.Metrics.Client.write_metric(metric)
  {:ok, %Zexbox.Metrics.Series.Generic{
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
  If there is an error while writing the metric, the function will log the error using the Logger module without crashing the process,
  """

  alias Zexbox.Metrics.{Connection, ControllerSeries, Series}
  alias Zexbox.Metrics.Context
  require Logger

  @type series :: ControllerSeries.t() | Series.t()

  @doc """
  Write a metric to InfluxDB.

  Skips writing (and returns `{:ok, metrics}`) when metrics are disabled for
  the current process or for any process in its caller chain (e.g. a request
  that called `Zexbox.Metrics.disable_for_process/0`).

  ## Examples

      iex> Zexbox.Metrics.Client.write_metric(%ControllerSeries{})
      {:ok, %ControllerSeries{}}

  """
  @spec write_metric(series()) :: tuple()
  def write_metric(%Series{} = metrics) do
    metrics
    |> Map.from_struct()
    |> write_to_influx()
  end

  def write_metric(metrics),
    do: write_to_influx(metrics)

  defp write_to_influx(metrics) do
    if Context.metrics_disabled?() do
      {:ok, metrics}
    else
      do_write_to_influx(metrics)
    end
  end

  defp do_write_to_influx(metrics) do
    Connection.write(metrics)
  rescue
    error ->
      Logger.debug("Failed to write metric to InfluxDB: #{inspect(error)}")
      {:error, inspect(error)}
  end
end
