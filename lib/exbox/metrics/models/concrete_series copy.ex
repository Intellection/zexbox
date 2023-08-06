# defmodule Exbox.Metrics.Models.ConcreteSeries do
#  @moduledoc """
#  A wrapper around instream series to abstract away from the library itself.
#  If we want to switch our library, we can extract the bits we need from this module.
#
#  There are some built in behaviours such as providing keys that are not specified in the module will automatically get discarded
#  ```elixir
#  defmodule MySeries.ControllerSeries do
#    use Exbox.Metrics.Models.ConcreteSeries
#
#    series do
#      measurement("controller_metrics")
#
#      tag(:controller)
#      tag(:action)
#      tag(:method)
#      tag(:format)
#      tag(:status)
#
#      field(:duration_ms)
#      field(:success)
#      field(:path)
#      field(:http_referer)
#      field(:trace_id)
#      field(:count)
#      field(:request_id)
#    end
#  end
#  ```
#  There are some helper functions for tag and field built in so that you can use it in the following way
#  ```elixir
#        point =
#        %ControllerMetrics{}
#        |> ControllerMetrics.tag(:method, metadata.conn.method)
#        |> ControllerMetrics.field(:count, 1)
#  ```
#
#  """
#
#  # use Instream.Series
#
#  defmodule MySeries do
#    use Instream.Series
#
#    series do
#      measurement(@default_series_definition[:measurement])
#      tags(@default_series_definition[:tags])
#      fields(@default_series_definition[:fields])
#    end
#
#    defstruct Instream.Series.fields_and_tags(@default_series_definition)
#  end
#
#  defmacro __using__(_opts) do
#    quote do
#      @before_compile unquote(__MODULE__)
#    end
#  end
#
#  @doc """
#  Adds a tag to the series
#  """
#  @spec tag(t(), atom(), any()) :: t()
#  def tag(%__MODULE__{} = series, key, value) do
#    %{series | tags: Map.put(series.tags, key, value)}
#  end
#
#  @doc """
#  Adds a field to the series
#  """
#  @spec field(t(), atom(), any()) :: t()
#  def field(%__MODULE__{} = series, key, value) do
#    %{series | fields: Map.put(series.fields, key, value)}
#  end
# end
