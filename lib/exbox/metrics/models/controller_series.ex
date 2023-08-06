defmodule Exbox.Metrics.ControllerMetrics do
  @moduledoc """
  This module defines generic controller metrics.

  The fields captured are:

  * duration_ms - The time taken to process the request in milliseconds
  * success - Whether the request was successful (1.0) or not (0.0)
  * path - The path of the request
  * http_referer - The referer of the request
  * count - The number of requests
  * request_id - The request ID of the request

  The tags allowed are:

  * controller - The name of the controller
  * action - The name of the action
  * method - The HTTP method of the request
  * format - The format of the request
  * status - The status of the request
  """
  use Instream.Series

  series do
    measurement("controller_metrics")

    tag(:controller)
    tag(:action)
    tag(:method)
    tag(:format)
    tag(:status)

    field(:duration_ms)
    field(:success)
    field(:path)
    field(:http_referer)
    field(:trace_id)
    field(:count)
    field(:request_id)
  end

  @doc """
  Adds a tag to the series
  """
  @spec tag(t(), atom(), any()) :: t()
  def tag(%__MODULE__{} = series, key, value) do
    %{series | tags: Map.put(series.tags, key, value)}
  end

  @doc """
  Adds a field to the series
  """
  @spec field(t(), atom(), any()) :: t()
  def field(%__MODULE__{} = series, key, value) do
    %{series | fields: Map.put(series.fields, key, value)}
  end
end
