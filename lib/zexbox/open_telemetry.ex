defmodule Zexbox.OpenTelemetry do
  @moduledoc """
  OpenTelemetry URL helpers for enriching Jira tickets with observability links.

  Mirrors `Opsbox::OpenTelemetry`. Reads from the current process's OTEL context
  (baggage and active span) via `opentelemetry_api`.

  All functions return `nil` gracefully when OTEL is unconfigured or there is no
  active span, so they are safe to call from any rescue block.

  ## Configuration

  ```elixir
  config :zexbox,
    service_name: "my-app",
    app_env: :production,         # :production | :sandbox | :dev | :test (defaults to Mix.env())
    tempo_datasource_uid: nil     # optional override for the Grafana Tempo datasource UID
  ```
  """

  @production_tempo_uid "een1tos42jnk0d"
  @sandbox_tempo_uid "eehwibr22b6kgb"
  @compile_env Mix.env()

  @doc """
  Returns `true` when the current OTEL span context is valid (non-zero trace ID).
  """
  @spec valid_active_span?() :: boolean()
  def valid_active_span? do
    ctx = get_span_ctx()
    ctx != nil && :otel_span.is_valid(ctx)
  rescue
    _e -> false
  end

  @doc """
  Returns a Grafana Tempo trace URL for the current span, or `nil` if no active span
  or if the environment is not `:production` or `:sandbox`.
  """
  @spec generate_trace_url() :: String.t() | nil
  def generate_trace_url do
    if valid_active_span?() && app_env() in [:production, :sandbox] do
      trace_id = hex_trace_id()
      pane_json = build_pane_json(trace_id)
      "https://zappi.grafana.net/explore?schemaVersion=1&panes=#{Jason.encode!(pane_json)}"
    end
  rescue
    _e -> nil
  end

  @doc """
  Returns a Kibana Discover URL for `:production` and `:sandbox` environments, `nil` otherwise.
  Includes the current trace ID in the query when an active span is present.
  """
  @spec kibana_log_url() :: String.t() | nil
  def kibana_log_url do
    env = app_env()

    if env in [:production, :sandbox] do
      trace_id = if valid_active_span?(), do: hex_trace_id(), else: nil
      service = Application.get_env(:zexbox, :service_name, "app")
      trace_part = if trace_id, do: "%20AND%20%22#{trace_id}%22", else: ""
      subdomain = if env == :production, do: "", else: "#{env}."
      app_encoded = URI.encode(service, &URI.char_unreserved?/1)

      "https://kibana.#{subdomain}zappi.tools/app/discover#/?_a=(columns:!(log.message),filters:!()," <>
        "query:(language:kuery,query:'zappi.app:%20%22#{app_encoded}%22#{trace_part}')," <>
        "sort:!(!('@timestamp',asc)))&_g=(filters:!(),time:(from:now-1d,to:now))"
    end
  rescue
    _e -> nil
  end

  # --- Private ---

  defp get_span_ctx do
    :otel_tracer.current_span_ctx()
  rescue
    _e -> nil
  catch
    _kind, _e -> nil
  end

  defp hex_trace_id do
    case get_span_ctx() do
      nil ->
        nil

      ctx ->
        ctx
        |> :otel_span.trace_id()
        |> Integer.to_string(16)
        |> String.pad_leading(32, "0")
        |> String.downcase()
    end
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
        :test -> "test"
        _env -> "development"
      end
  end

  defp app_env, do: Application.get_env(:zexbox, :app_env, @compile_env)
end
