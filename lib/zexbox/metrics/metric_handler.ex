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
  @spec handle_event(list(atom()), map(), map(), map()) :: any()
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    case required_fields_missing?(metadata) do
      false ->
        Logger.info("Creating controller series")

        measurements
        |> create_controller_series(metadata)
        |> write_metric(config)

      true ->
        Logger.info("Required fields not present in metadata")
        nil
    end
  rescue
    exception ->
      Logger.error("Exception creating controller series: #{inspect(exception)}")
  end

  defp required_fields_missing?(%{conn: %{private: private}}) do
    format = Map.get(private, :phoenix_format)
    controller = Map.get(private, :phoenix_controller)

    is_nil(format) || is_nil(controller)
  end

  defp required_fields_missing?(_metadata) do
    true
  end

  defp create_controller_series(measurements, metadata) do
    status = metadata.conn.status

    action =
      metadata.conn.private
      |> Map.get(:phoenix_action)
      |> Atom.to_string()

    controller =
      Atom.to_string(metadata.conn.private.phoenix_controller)

    %ControllerSeries{}
    |> ControllerSeries.tag(:method, metadata.conn.method)
    |> ControllerSeries.tag(:status, status)
    |> ControllerSeries.tag(:action, action)
    |> ControllerSeries.tag(:format, metadata.conn.private.phoenix_format)
    |> ControllerSeries.tag(:controller, controller)
    |> ControllerSeries.field(:count, 1)
    |> ControllerSeries.field(:success, success?(status))
    |> ControllerSeries.field(:path, metadata.conn.request_path)
    |> ControllerSeries.field(:duration_ms, duration(measurements))
    |> set_referer_field(metadata)
    |> set_trace_id_field(metadata)
  end

  defp set_trace_id_field(series, metadata) do
    case trace_id(metadata) do
      nil ->
        series

      trace_id ->
        ControllerSeries.field(series, :trace_id, trace_id)
    end
  end

  defp trace_id(metadata) do
    metadata.conn
    |> Map.get(:assigns, %{})
    |> Map.get(:trace_id)
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
