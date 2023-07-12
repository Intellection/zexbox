defmodule Exbox.Metrics.Series.ControllerMetrics do
  @moduledoc """
  This module defines generic controller metrics.
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
    field(:duration_db_ms)
    field(:success)
    field(:path)
    field(:http_referer)
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
