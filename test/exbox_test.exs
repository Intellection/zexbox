defmodule ExboxTest do
  use ExUnit.Case

  setup %{} do
    Application.put_env(:exbox, Exbox.Metrics.Connection, [])
  end

  describe "start_link/1" do
    test "starts the Exbox supervisor and applies default configurations" do
      assert {:ok, _pid} = Exbox.start_link(nil)
    end
  end

  describe "init/1" do
    test "initializes the Exbox supervisor with child processes" do
      {:ok, _pid} = Supervisor.start_link(Exbox, nil)
    end
  end
end
