defmodule Zexbox.Metrics.ControllerSeriesEnricher do
  @moduledoc """
  Behaviour for enriching a `Zexbox.Metrics.ControllerSeries` with values
  derived from the request before it is written to InfluxDB.

  This is the extension point for setting tags and fields on the controller
  series that `Zexbox` does not know how to populate itself — for example,
  identifying the caller via an API key description, propagating a tenant
  identifier, or attaching anything else that lives on the `conn`.

  ## Configuring an enricher

  Pass the enricher when starting `Zexbox.Metrics`:

      children = [
        {Zexbox.Metrics, enricher: {MyApp.MetricsEnricher, []}}
      ]

  Or configure it via application env:

      config :zexbox, :metrics_enricher, {MyApp.MetricsEnricher, []}

  The form `MyApp.MetricsEnricher` (without options) is also accepted and is
  equivalent to `{MyApp.MetricsEnricher, []}`.

  ## Implementing an enricher

  Read whatever you need off the `conn` — typically values placed there by an
  earlier plug — and return a new series. The recommended pattern is to do any
  expensive work (e.g. database lookups) in your auth plug and stash the result
  on `conn.assigns`, so the enricher just reads it:

      defmodule MyApp.MetricsEnricher do
        @behaviour Zexbox.Metrics.ControllerSeriesEnricher

        alias Zexbox.Metrics.ControllerSeries

        @impl true
        def init(opts), do: opts

        @impl true
        def call(series, conn, _opts) do
          case conn.assigns[:api_key_description] do
            nil -> series
            description -> ControllerSeries.field(series, :requester, description)
          end
        end
      end

  Enricher exceptions are caught by `Zexbox.Metrics.MetricHandler` and logged;
  the un-enriched series is still written. Avoid blocking work inside `call/3`
  — it runs in the request process.
  """

  alias Zexbox.Metrics.ControllerSeries

  @callback init(opts :: any()) :: any()
  @callback call(series :: ControllerSeries.t(), conn :: map(), opts :: any()) ::
              ControllerSeries.t()
end
