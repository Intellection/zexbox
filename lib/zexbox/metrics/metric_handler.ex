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
    |> ControllerSeries.tag(:status, status)
    |> set_action_tag(metadata)
    |> set_format_tag(metadata)
    |> set_controller_tag(metadata)
    |> ControllerSeries.field(:count, 1)
    |> ControllerSeries.field(:success, success?(status))
    |> ControllerSeries.field(:path, metadata.conn.request_path)
    |> ControllerSeries.field(:duration_ms, duration(measurements))
    |> set_referer_field(metadata)
    |> set_trace_id_field(metadata)
    |> write_metric(config)
  rescue
    exception ->
      Logger.debug("Exception creating controller series: #{inspect(exception)}")
  end

  defp set_action_tag(series, metadata) do
    case metadata.conn[:private][:phoenix_action] do
      nil ->
        series

      action ->
        ControllerSeries.tag(series, :action, Atom.to_string(action))
    end
  end

  defp set_format_tag(series, metadata) do
    case metadata.conn[:private][:phoenix_format] do
      nil ->
        series

      format ->
        ControllerSeries.tag(series, :format, format)
    end
  end

  defp set_controller_tag(series, metadata) do
    case metadata.conn[:private][:phoenix_controller] do
      nil ->
        series

      controller ->
        ControllerSeries.tag(series, :controller, Atom.to_string(controller))
    end
  end

  defp set_trace_id_field(series, metadata) do
    case metadata.conn[:assigns][:trace_id] do
      nil ->
        series

      trace_id ->
        ControllerSeries.field(series, :trace_id, trace_id)
    end
  end

  defp set_referer_field(series, metadata) do
    case Enum.find(metadata.conn.req_headers, fn {key, _value} -> key == "referer" end) do
      nil ->
        series

      {_key, value} ->
        ControllerSeries.field(series, :http_referer, value)
    end
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

  defp write_metric(metric, %{metric_client: client}) do
    client.write_metric(metric)
  end

  defp write_metric(metric, _config) do
    Client.write_metric(metric)
  end
end
