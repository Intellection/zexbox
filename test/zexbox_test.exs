defmodule ZexboxTest do
  use ExUnit.Case

  setup %{} do
    Application.put_env(:zexbox, Zexbox.Metrics.Connection, [])
  end

  describe "start_link/1" do
    test "starts the Zexbox supervisor and applies default configurations" do
      assert {:ok, _pid} = Zexbox.start_link(nil)
    end
  end

  describe "init/1" do
    test "initializes the Zexbox supervisor with child processes" do
      {:ok, _pid} = Supervisor.start_link(Zexbox, nil)
    end
  end
end
