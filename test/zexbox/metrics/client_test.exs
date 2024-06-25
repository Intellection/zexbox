defmodule Zexbox.Metrics.ClientTest do
  use ExUnit.Case
  import Mock
  alias Zexbox.Metrics.{Client, Connection, Series}

  @map %{
    measurement: "my_measurement",
    fields: %{
      "my_field" => 1
    },
    tags: %{
      "my_tag" => "my_value"
    }
  }

  describe "write_metric/1" do
    test_with_mock "when given a series", Connection, write: fn metrics -> {:ok, metrics} end do
      series = struct(Series, @map)
      assert {:ok, @map} = Client.write_metric(series)
    end

    test_with_mock "when given a map", Connection, write: fn metrics -> {:ok, metrics} end do
      assert {:ok, @map} = Client.write_metric(@map)
    end
  end
end
