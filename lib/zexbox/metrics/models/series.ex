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

  def new(measurement) do
    %__MODULE__{
      measurement: measurement,
      timestamp: DateTime.utc_now(),
      fields: %{},
      tags: %{}
    }
  end

  def field(series, key, value) do
    %{series | fields: Map.put(series.fields, key, value)}
  end

  def tag(series, key, value) do
    %{series | tags: Map.put(series.tags, key, value)}
  end
end
