defmodule Exbox.Metrics.Series.ControllerMetricsTest do
  use ExUnit.Case

  alias Exbox.Metrics.Series.ControllerMetrics

  describe "tag/3" do
    test "adds a tag to the series" do
      series = %ControllerMetrics{}

      tagged_series = ControllerMetrics.tag(series, :controller, "MyController")

      assert tagged_series.tags.controller == "MyController"
    end
  end

  describe "field/3" do
    test "adds a field to the series" do
      series = %ControllerMetrics{}

      field_series = ControllerMetrics.field(series, :duration_ms, 100)

      assert field_series.fields.duration_ms == 100
    end
  end
end
