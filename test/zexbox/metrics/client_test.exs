defmodule Zexbox.Metrics.ClientTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock
  alias Zexbox.Metrics.{Client, Connection, Series}

  setup_all do
    ensure_registry_started()
    :ok
  end

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
    test_with_mock "writes the metric when given a series", Connection,
      write: fn metrics -> {:ok, metrics} end do
      series = struct(Series, @map)
      assert {:ok, @map} = Client.write_metric(series)
    end

    test_with_mock "writes the metric when given a map", Connection,
      write: fn metrics -> {:ok, metrics} end do
      assert {:ok, @map} = Client.write_metric(@map)
    end

    test_with_mock "logs any errors that might occur while writing metrics", Connection,
      write: fn _metrics -> raise "Bork" end do
      assert capture_log(fn ->
               assert {:error, "%RuntimeError{message: \"Bork\"}"} = Client.write_metric(@map)
             end) =~ "Failed to write metric to InfluxDB: %RuntimeError{message: \"Bork\"}"
    end

    test_with_mock "skips writing and returns {:ok, metrics} when metrics disabled for process", Connection,
      write: fn _metrics -> raise "should not be called" end do
      Zexbox.Metrics.disable_for_process()
      assert {:ok, @map} = Client.write_metric(@map)
      Zexbox.Metrics.enable_for_process()
    end

    test_with_mock "skips writing from task when parent process disabled metrics", Connection,
      write: fn _metrics -> raise "should not be called" end do
      Zexbox.Metrics.disable_for_process()
      task =
        Task.async(fn ->
          Client.write_metric(@map)
        end)
      assert {:ok, @map} = Task.await(task)
      Zexbox.Metrics.enable_for_process()
    end
  end

  defp ensure_registry_started do
    case Process.whereis(Zexbox.Metrics.ContextRegistry) do
      nil -> {:ok, _pid} = Zexbox.Metrics.ContextRegistry.start_link()
      _pid -> :ok
    end
  end
end
