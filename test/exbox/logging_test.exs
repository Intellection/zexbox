defmodule Zexbox.LoggingTest do
  use ExUnit.Case

  import Zexbox.Logging

  describe "attach_controller_logs/0" do
    test "attaches logging for controller stop and start events" do
      Application.put_env(:exbox, Zexbox.Metrics.Connection, [])
      {:ok, _pid} = Supervisor.start_link(Zexbox, nil)
      attach_controller_logs()

      # Add assertions here to verify the attachment of controller logs for stop and start events
    end
  end

  describe "attach_telemetry/3" do
    setup do
      Application.put_env(:exbox, :features, capture_telemetry_log_events: true)
      :ok
    end

    test "attaches telemetry logs when capture_telemetry_log_events? is true" do
      assert attach_telemetry("my_event", [:my, :event], fn _event,
                                                            _measurements,
                                                            _metadata,
                                                            _config ->
               :ok
             end) ==
               :ok
    end

    test "does not attach telemetry logs when capture_telemetry_log_events? is false" do
      Application.put_env(:exbox, :features, capture_telemetry_log_events: false)
      assert attach_telemetry("my_event", [:my, :event], fn _event -> :ok end) == nil
    end
  end
end
