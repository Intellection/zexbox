defmodule Zexbox.Metrics.MetricHandler do
  @moduledoc """
  This module is responsible for logging controller metrics to influx
  """
  alias Zexbox.Metrics.{Client, ControllerSeries}
  require Logger

  @doc """
  This function is called by the Phoenix endpoint when a controller action is
  finished. It will log the controller metrics to influx.

  ## Examples

      iex> Zexbox.Metrics.MetricHandler.handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config)
      :ok

  """
  @spec handle_event(list(atom), map, map, map) :: any()
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    status = metadata.conn.status

    %ControllerSeries{}
    |> ControllerSeries.tag(:method, metadata.conn.method)
    |> ControllerSeries.tag(
      :action,
      Atom.to_string(Map.get(metadata.conn.private, :phoenix_action, nil))
    )
    |> ControllerSeries.tag(:format, metadata.conn.private.phoenix_format)
    |> ControllerSeries.tag(:status, status)
    |> ControllerSeries.tag(
      :controller,
      Atom.to_string(metadata.conn.private.phoenix_controller)
    )
    |> ControllerSeries.field(:count, 1)
    |> ControllerSeries.field(:trace_id, "empty_for_now")
    |> ControllerSeries.field(:success, success?(status))
    |> ControllerSeries.field(:path, metadata.conn.request_path)
    |> ControllerSeries.field(:http_referer, referer(metadata.conn))
    |> ControllerSeries.field(:duration_ms, duration(measurements))
    |> write_metric(config)
  end

  defp write_metric(metric, %{metric_client: client}) do
    client.write_metric(metric)
  end

  defp write_metric(metric, _config) do
    Client.write_metric(metric)
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
    case Enum.find(conn.req_headers, fn {key, __value} -> key == "referer" end) do
      {_key, value} -> value
      nil -> nil
    end
  end
end
