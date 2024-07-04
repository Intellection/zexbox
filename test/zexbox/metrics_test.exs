defmodule Zexbox.MetricsTest do
  use ExUnit.Case
  alias Zexbox.Metrics

  test "start_link/1 starts the metrics supervisor" do
    {:ok, pid} = Metrics.start_link(nil)
    assert Process.alive?(pid)
  end

  test "init/1 initializes the metrics supervisor" do
    assert {:ok,
            {%{intensity: 3, period: 5, strategy: :one_for_one},
             [
               %{
                 id: Zexbox.Metrics.Connection,
                 start: {Instream.Connection.Supervisor, :start_link, [Zexbox.Metrics.Connection]}
               }
             ]}} = Metrics.init(nil)
  end
end
