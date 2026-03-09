defmodule Zexbox.OpenTelemetryTest do
  use ExUnit.Case
  import Mock
  alias Zexbox.OpenTelemetry

  # A fake span context atom used as a stand-in for the opaque OTEL span record.
  @mock_ctx :mock_span_ctx

  # Hex representation of the integer 255 padded to 32 chars.
  @mock_trace_id_int 255
  @mock_trace_id_hex String.pad_leading("ff", 32, "0")

  defp with_active_span(fun) do
    with_mocks([
      {:otel_tracer, [], [current_span_ctx: fn -> @mock_ctx end]},
      {:otel_span, [],
       [is_valid: fn @mock_ctx -> true end, trace_id: fn @mock_ctx -> @mock_trace_id_int end]}
    ]) do
      fun.()
    end
  end

  defp with_no_span(fun) do
    with_mocks([
      {:otel_tracer, [], [current_span_ctx: fn -> :undefined end]},
      {:otel_span, [], [is_valid: fn :undefined -> false end]}
    ]) do
      fun.()
    end
  end

  setup do
    on_exit(fn ->
      Application.delete_env(:zexbox, :app_env)
      Application.delete_env(:zexbox, :service_name)
      Application.delete_env(:zexbox, :tempo_datasource_uid)
    end)

    :ok
  end

  describe "valid_active_span?/0" do
    test "returns true when the current span is valid" do
      with_active_span(fn ->
        assert OpenTelemetry.valid_active_span?() == true
      end)
    end

    test "returns false when there is no active span" do
      with_no_span(fn ->
        assert OpenTelemetry.valid_active_span?() == false
      end)
    end

    test "returns false when OTEL raises" do
      with_mock :otel_tracer, current_span_ctx: fn -> raise "otel not running" end do
        assert OpenTelemetry.valid_active_span?() == false
      end
    end
  end

  describe "generate_trace_url/0" do
    test "returns nil when there is no active span" do
      with_no_span(fn ->
        assert OpenTelemetry.generate_trace_url() == nil
      end)
    end

    test "returns a Grafana Tempo URL when there is an active span" do
      Application.put_env(:zexbox, :app_env, :production)

      with_active_span(fn ->
        url = OpenTelemetry.generate_trace_url()
        assert url =~ "zappi.grafana.net"
        assert url =~ @mock_trace_id_hex
      end)
    end

    test "Grafana URL encodes the pane JSON with the trace ID and datasource UID" do
      Application.put_env(:zexbox, :app_env, :production)
      Application.put_env(:zexbox, :tempo_datasource_uid, "test-uid")

      with_active_span(fn ->
        url = OpenTelemetry.generate_trace_url()
        assert url =~ "test-uid"
        assert url =~ @mock_trace_id_hex
      end)
    end

    test "returns nil in non-production environments" do
      Application.put_env(:zexbox, :app_env, :dev)

      with_active_span(fn ->
        assert OpenTelemetry.generate_trace_url() == nil
      end)
    end

    test "returns nil when OTEL raises" do
      with_mock :otel_tracer, current_span_ctx: fn -> raise "otel not running" end do
        assert OpenTelemetry.generate_trace_url() == nil
      end
    end
  end

  describe "kibana_log_url/0" do
    test "returns nil for :test environment" do
      Application.put_env(:zexbox, :app_env, :test)

      with_no_span(fn ->
        assert OpenTelemetry.kibana_log_url() == nil
      end)
    end

    test "returns nil for :dev environment" do
      Application.put_env(:zexbox, :app_env, :dev)

      with_no_span(fn ->
        assert OpenTelemetry.kibana_log_url() == nil
      end)
    end

    test "returns a Kibana URL for :production environment" do
      Application.put_env(:zexbox, :app_env, :production)
      Application.put_env(:zexbox, :service_name, "my-app")

      with_no_span(fn ->
        url = OpenTelemetry.kibana_log_url()
        assert url =~ "kibana.zappi.tools"
        assert url =~ "my-app"
        refute url =~ "sandbox"
      end)
    end

    test "returns a Kibana URL for :sandbox environment with subdomain" do
      Application.put_env(:zexbox, :app_env, :sandbox)
      Application.put_env(:zexbox, :service_name, "my-app")

      with_no_span(fn ->
        url = OpenTelemetry.kibana_log_url()
        assert url =~ "kibana.sandbox.zappi.tools"
        assert url =~ "my-app"
      end)
    end

    test "URL-encodes the service name" do
      Application.put_env(:zexbox, :app_env, :production)
      Application.put_env(:zexbox, :service_name, "my app")

      with_no_span(fn ->
        url = OpenTelemetry.kibana_log_url()
        assert url =~ "my%20app"
      end)
    end

    test "includes the trace ID in the URL when a span is active" do
      Application.put_env(:zexbox, :app_env, :production)

      with_active_span(fn ->
        url = OpenTelemetry.kibana_log_url()
        assert url =~ @mock_trace_id_hex
      end)
    end

    test "omits the trace part when no active span" do
      Application.put_env(:zexbox, :app_env, :production)

      with_no_span(fn ->
        url = OpenTelemetry.kibana_log_url()
        refute url =~ "AND"
      end)
    end

    test "omits trace ID when OTEL raises (returns URL without trace filter)" do
      Application.put_env(:zexbox, :app_env, :production)

      with_mock :otel_tracer, current_span_ctx: fn -> raise "otel not running" end do
        url = OpenTelemetry.kibana_log_url()
        assert url =~ "kibana.zappi.tools"
        refute url =~ "AND"
      end
    end
  end
end
