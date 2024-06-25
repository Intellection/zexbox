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
  alias Zexbox.Metrics.MetricHandler
  alias Zexbox.Telemetry

  @doc """
  Initializes the supervisor with the required child processes.

  ## Examples

      iex> Zexbox.Metrics.init(nil)
      {:ok,
       {%{intensity: 3, period: 5, strategy: :one_for_one, auto_shutdown: :never},
        [
          %{
            id: Zexbox.Metrics.Connection,
            start: {Instream.Connection.Supervisor, :start_link, [Zexbox.Metrics.Connection]}
          }
        ]}}
  """
  @impl Supervisor
  def init(_args) do
    children = [Zexbox.Metrics.Connection]
    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
  Starts the metrics supervisor and attaches the controller metrics.

  ## Examples

        iex> Zexbox.Metrics.start_link(nil)
        {:ok, #PID<0.123.0>}

  """
  @spec start_link(args :: any()) :: Supervisor.on_start()
  def start_link(_args) do
    attach_controller_metrics()
    Supervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  defp attach_controller_metrics do
    Telemetry.attach(
      "phoenix_controller_metrics",
      [:phoenix, :endpoint, :stop],
      &MetricHandler.handle_event/4,
      nil
    )
  end
end
