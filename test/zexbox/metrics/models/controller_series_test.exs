defmodule Zexbox.Metrics.ControllerSeriesTest do
  use ExUnit.Case
  alias Zexbox.Metrics.ControllerSeries

  describe "tag/3" do
    test "adds a tag to the series" do
      series = %ControllerSeries{}

      tagged_series = ControllerSeries.tag(series, :controller, "MyController")

      assert tagged_series.tags.controller == "MyController"
    end
  end

  describe "field/3" do
    test "adds a field to the series" do
      series = %ControllerSeries{}

      field_series = ControllerSeries.field(series, :duration_ms, 100)

      assert field_series.fields.duration_ms == 100
    end
  end
end
