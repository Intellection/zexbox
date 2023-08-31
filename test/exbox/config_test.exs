defmodule Zexbox.ConfigTest do
  use ExUnit.Case

  import Zexbox.Config

  describe "capture_telemetry_metric_events?" do
    test "returns default value when not overridden in config" do
      Application.put_env(:zexbox, :features, %{})
      assert capture_telemetry_metric_events?() == true
    end

    test "returns overridden value from application config" do
      Application.put_env(:zexbox, :features, capture_telemetry_metric_events: false)
      assert capture_telemetry_metric_events?() == false
    end
  end

  describe "capture_telemetry_log_events?" do
    test "returns default value when not overridden in config" do
      Application.put_env(:zexbox, :features, %{})
      assert capture_telemetry_log_events?() == false
    end

    test "returns overridden value from application config" do
      Application.put_env(:zexbox, :features, capture_telemetry_log_events: true)
      assert capture_telemetry_log_events?() == true
    end
  end

  describe "config_value" do
    test "returns default value when key not present in config" do
      assert config_value(:non_existent_key) == nil
    end

    test "returns overridden value from application config" do
      Application.put_env(:zexbox, :features, capture_telemetry_metric_events: false)
      assert config_value(:capture_telemetry_metric_events) == false
    end

    test "returns default value when overridden value is nil in application config" do
      Application.put_env(:zexbox, :features, capture_telemetry_metric_events: nil)
      assert config_value(:capture_telemetry_metric_events) == true
    end
  end
end
