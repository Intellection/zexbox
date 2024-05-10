defmodule Zexbox.Metrics.Series do
  @moduledoc """
  This module defines a simple struct to write metrics to InfluxDB.

  the attributes are:
  * measurement - The name of the measurement
  * fields - The fields of the measurement, these are the values you want to aggregate on
  * tags - The tags of the measurement, these are usually identifiers for the values but you can't aggregate on them
  * timestamp - The timestamp of the measurement, it is optional, if it's missing in the struct, InfluxDB will use the current time
  """
  @enforce_keys ~w(measurement fields tags)a
  @type t :: %__MODULE__{
          measurement: String.t(),
          fields: map(),
          tags: map(),
          timestamp: DateTime.t() | nil
        }

  defstruct measurement: "my_measurement",
            fields: %{},
            tags: %{},
            timestamp: nil

  @doc """
  Creates a new struct with the given measurement and the current time as the timestamp

  ## Examples

      iex> Series.new("my_measurement")
      %Series{
        measurement: "my_measurement",
        fields: %{},
        tags: %{},
        timestamp: ~U[2021-09-29 12:00:00Z]
      }
  """
  @spec new(String.t()) :: t()
  def new(measurement) do
    %__MODULE__{
      measurement: measurement,
      timestamp: DateTime.utc_now(),
      fields: %{},
      tags: %{}
    }
  end

  @doc """
  Adds a field to the series

  ## Examples

      iex> Series.field(%Series{measurement: "my_measurement"}, :field1, 42)
      %Series{
        measurement: "my_measurement",
        fields: %{field1: 42},
        tags: %{},
        timestamp: ~U[2021-09-29 12:00:00Z]
      }
  """
  @spec field(t(), atom(), any()) :: t()
  def field(series, key, value) do
    %{series | fields: Map.put(series.fields, key, value)}
  end

  @doc """
  Adds a tag to the series

  ## Examples

      iex> Series.tag(%Series{measurement: "my_measurement"}, :tag1, "tag_value")
      %Series{
        measurement: "my_measurement",
        fields: %{},
        tags: %{tag1: "tag_value"},
        timestamp: ~U[2021-09-29 12:00:00Z]
      }
  """
  @spec tag(t(), atom(), any()) :: t()
  def tag(series, key, value) do
    %{series | tags: Map.put(series.tags, key, value)}
  end
end
