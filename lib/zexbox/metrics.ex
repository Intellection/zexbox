defmodule Zexbox.Metrics do
  @moduledoc """
  This module is esponsible for setting up and supervising the metrics collection and telemetry.
  It attaches telemetry handlers for capturing metrics related to your Phoenix endpoints.

  ```elixir
  def start(_type, args) do
    children = [{Zexbox.Metrics, []}]
    Supervisor.start_link(children, opts)
  end
  ```
  """

  use Supervisor
  alias Zexbox.Metrics.{Context, MetricHandler}
  alias Zexbox.Telemetry

  @doc """
  Initializes the supervisor with the required child processes.

  ## Examples

      iex> Zexbox.Metrics.init(nil)
      {:ok,
       {%{intensity: 3, period: 5, strategy: :one_for_one, auto_shutdown: :never},
        [
          %{id: Zexbox.Metrics.ContextRegistry, ...},
          %{
            id: Zexbox.Metrics.Connection,
            start: {Instream.Connection.Supervisor, :start_link, [Zexbox.Metrics.Connection]}
          }
        ]}}
  """
  @impl Supervisor
  def init(_args) do
    children = [
      Zexbox.Metrics.ContextRegistry,
      Zexbox.Metrics.Connection
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Disables metric writing for the current process. Writes from this process
  (and from tasks spawned with `Task.async` that have this process in `$callers`)
  will be skipped until `enable_for_process/0` is called or the process exits.

  Use this in a Plug or elsewhere when you want to suppress metrics for a request
  (e.g. when a header indicates a test or health check).
  """
  @spec disable_for_process() :: :ok
  def disable_for_process, do: Context.disable_for_process()

  @doc """
  Re-enables metric writing for the current process.
  """
  @spec enable_for_process() :: :ok
  def enable_for_process, do: Context.enable_for_process()

  @doc """
  Returns true if the current process has disabled metrics.
  """
  @spec disabled?() :: boolean()
  def disabled?, do: Context.disabled?()

  @doc """
  Starts the metrics supervisor and attaches the controller metrics.

  Accepts an optional `:enricher` to customise the controller series before it
  is written. See `Zexbox.Metrics.ControllerSeriesEnricher`.

      children = [
        {Zexbox.Metrics, enricher: {MyApp.MetricsEnricher, []}}
      ]

  An enricher can also be set via application env
  (`config :zexbox, :metrics_enricher, {MyApp.MetricsEnricher, []}`); the
  `start_link/1` argument wins if both are present.

  ## Examples

        iex> Zexbox.Metrics.start_link(nil)
        {:ok, #PID<0.123.0>}

  """
  @spec start_link(args :: any()) :: Supervisor.on_start()
  def start_link(args) do
    on_start = Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
    attach_controller_metrics(resolve_enricher(args))
    on_start
  end

  defp resolve_enricher(args) do
    args
    |> enricher_from_args()
    |> case do
      nil -> Application.get_env(:zexbox, :metrics_enricher)
      value -> value
    end
    |> normalise_enricher()
  end

  defp enricher_from_args(args) when is_list(args), do: Keyword.get(args, :enricher)
  defp enricher_from_args(_args), do: nil

  defp normalise_enricher(nil), do: nil

  defp normalise_enricher({module, opts}) when is_atom(module) do
    {module, module.init(opts)}
  end

  defp normalise_enricher(module) when is_atom(module) do
    {module, module.init([])}
  end

  defp attach_controller_metrics(enricher) do
    Telemetry.attach(
      "phoenix_controller_metrics",
      [:phoenix, :endpoint, :stop],
      &MetricHandler.handle_event/4,
      %{enricher: enricher}
    )
  end
end
