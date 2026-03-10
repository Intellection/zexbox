defmodule Zexbox.OpenTelemetry do
  @moduledoc """
  OpenTelemetry URL helpers for enriching Jira tickets with observability links.

  Mirrors `Opsbox::OpenTelemetry`. Reads from the current process's OTEL context
  via `opentelemetry_api`.

  All functions return `nil` gracefully when OTEL is unconfigured or there is no
  active span, so they are safe to call from any rescue block.

  ## Configuration

  ```elixir
  config :zexbox,
    service_name: "my-app",
    app_env: :production,       # :production | :sandbox | :dev | :test
    tempo_datasource_uid: nil   # optional override for the Grafana Tempo datasource UID
  ```
  """

  @production_tempo_uid "een1tos42jnk0d"
  @sandbox_tempo_uid "eehwibr22b6kgb"
  @grafana_host "zappi.grafana.net"
  @kibana_host "zappi.tools"

  @doc """
  Returns a Grafana Tempo trace URL for the current span, or `nil` if no active span
  or if the environment is not `:production` or `:sandbox`.
  """
  @spec generate_trace_url() :: String.t() | nil
  def generate_trace_url do
    build_trace_url(get_span_context())
  rescue
    _e -> nil
  end

  @doc """
  Returns a Kibana Discover URL for `:production` and `:sandbox` environments, `nil` otherwise.
  Includes the current trace ID in the query when an active span is present.
  """
  @spec kibana_log_url() :: String.t() | nil
  def kibana_log_url do
    build_kibana_url(get_span_context())
  rescue
    _e -> nil
  end

  # --- Private ---

  defp build_trace_url(nil), do: nil

  defp build_trace_url(context) do
    if app_env() in [:production, :sandbox] && :otel_span.is_valid(context) do
      trace_id = hex_trace_id(context)
      pane_json = build_pane_json(trace_id)
      "https://#{@grafana_host}/explore?schemaVersion=1&panes=#{Jason.encode!(pane_json)}"
    end
  end

  defp build_kibana_url(context) do
    env = app_env()

    if env in [:production, :sandbox] do
      service = Application.get_env(:zexbox, :service_name, "app")
      app_encoded = URI.encode(service, &URI.char_unreserved?/1)
      trace_part = trace_filter(context)

      "https://kibana.#{kibana_subdomain(env)}#{@kibana_host}/app/discover#/?_a=(columns:!(log.message),filters:!()," <>
        "query:(language:kuery,query:'zappi.app:%20%22#{app_encoded}%22#{trace_part}')," <>
        "sort:!(!('@timestamp',asc)))&_g=(filters:!(),time:(from:now-1d,to:now))"
    end
  end

  defp kibana_subdomain(:production), do: ""
  defp kibana_subdomain(env), do: "#{env}."

  defp trace_filter(nil), do: ""

  defp trace_filter(context) do
    if :otel_span.is_valid(context),
      do: "%20AND%20%22#{hex_trace_id(context)}%22",
      else: ""
  end

  defp get_span_context do
    case :otel_tracer.current_span_ctx() do
      :undefined -> nil
      context -> context
    end
  rescue
    _e -> nil
  catch
    _kind, _e -> nil
  end

  defp hex_trace_id(context) do
    context
    |> :otel_span.trace_id()
    |> Integer.to_string(16)
    |> String.pad_leading(32, "0")
    |> String.downcase()
  end

  defp build_pane_json(trace_id) do
    uid = tempo_datasource_uid()

    %{
      plo: %{
        datasource: uid,
        queries: [
          %{
            refId: "A",
            datasource: %{type: "tempo", uid: uid},
            queryType: "traceql",
            limit: 20,
            tableType: "traces",
            metricsQueryType: "range",
            query: trace_id
          }
        ],
        range: %{from: "now-1h", to: "now"}
      }
    }
  end

  defp tempo_datasource_uid do
    Application.get_env(:zexbox, :tempo_datasource_uid) ||
      case app_env() do
        :production -> @production_tempo_uid
        :sandbox -> @sandbox_tempo_uid
        _env -> nil
      end
  end

  defp app_env, do: Application.get_env(:zexbox, :app_env, :test)
end
