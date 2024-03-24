defmodule Zexbox.Metrics.SeriesTest do
  use ExUnit.Case

  alias Zexbox.Metrics.Series

  test "creates a default struct with correct defaults" do
    metric = %Series{
      measurement: "my_measurement",
      fields: %{},
      tags: %{},
      timestamp: nil
    }

    assert metric.measurement == "my_measurement"
    assert metric.fields == %{}
    assert metric.tags == %{}
    assert metric.timestamp == nil
  end

  test "creates a struct with custom values" do
    measurement = "custom_measurement"
    fields = %{field1: 42, field2: "hello"}
    tags = %{tag1: "tag_value", tag2: 123}
    timestamp = DateTime.utc_now()

    metric = %Series{measurement: measurement, fields: fields, tags: tags, timestamp: timestamp}

    assert metric.measurement == measurement
    assert metric.fields == fields
    assert metric.tags == tags
    assert metric.timestamp == timestamp
  end
end
