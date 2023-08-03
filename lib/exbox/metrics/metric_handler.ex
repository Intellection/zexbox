defmodule Exbox.Metrics.MetricHandler do
  @moduledoc """
  This module is responsible for logging controller metrics to influx
  """
  alias Exbox.Metrics.Client
  alias Exbox.Metrics.Series.ControllerMetrics
  require Logger

  @doc """
  This function is called by the Phoenix endpoint when a controller action is
  finished. It will log the controller metrics to influx.

  Examples:

      iex> Exbox.Metrics.MetricHandler.handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config)
      :ok
  """
  @spec handle_event(list(atom), map, map, map) :: any()
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    try do
      status = metadata.conn.status

      point =
        %ControllerMetrics{}
        |> ControllerMetrics.tag(:method, metadata.conn.method)
        |> ControllerMetrics.tag(:action, Atom.to_string(metadata.conn.private.phoenix_action))
        |> ControllerMetrics.tag(:format, metadata.conn.private.phoenix_format)
        |> ControllerMetrics.tag(:status, status)
        |> ControllerMetrics.tag(
          :controller,
          Atom.to_string(metadata.conn.private.phoenix_controller)
        )
        |> ControllerMetrics.field(:count, 1)
        |> ControllerMetrics.field(:success, success?(status))
        |> ControllerMetrics.field(:path, metadata.conn.request_path)
        |> ControllerMetrics.field(:http_referer, referer(metadata.conn))
        |> ControllerMetrics.field(:duration_ms, duration(measurements))

      point
      |> write_metric(config)
    rescue
      exception ->
        Logger.debug("Exception creating controller series: #{inspect(exception)}")
    end
  end

  defp write_metric(metric, %{metric_client: client}) do
    metric
    |> client.write_metric()
  end

  defp write_metric(metric, _config) do
    metric
    |> Client.write_metric()
  end

  defp duration(measurements) do
    System.convert_time_unit(measurements.duration, :native, :millisecond)
  end

  defp success?(status) do
    case status do
      status when status in 200..399 -> 1.0
      _status -> 0.0
    end
  end

  defp referer(conn) do
    conn.req_headers
    |> Enum.find(fn {k, _} -> k == "referer" end)
    |> elem(1)
  end
end
