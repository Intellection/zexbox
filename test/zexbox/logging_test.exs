defmodule Zexbox.LoggingTest do
  use ExUnit.Case
  alias Zexbox.Logging

  test "attach_controller_logs!/0 attaches logging for controller stop and start events" do
    Application.put_env(:zexbox, Zexbox.Metrics.Connection, [])

    assert :ok = Logging.attach_controller_logs!()

    assert_raise RuntimeError, "Phoenix controller logs already attached", fn ->
      Logging.attach_controller_logs!()
    end

    Application.delete_env(:zexbox, Zexbox.Metrics.Connection)
  end
end
