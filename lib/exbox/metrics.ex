defmodule Exbox.Metrics do
  @moduledoc """
  A module for handling and standardising metrics in Exbox applications.

  To use this module you must have the Telemetry library installed.
  To do so, add {:telemetry, "~> 1.2.1"} to your list of dependencies in mix.exs.

  To start the connection, you need to start the Exbox.Metrics.Connection
  as an application in your supervision tree:

      iex> def start(_type, _args) do
      iex>   children = [
      iex>     {Exbox.Metrics.Connection, []}
      iex>   ]
      iex>   Supervisor.start_link(children, strategy: :one_for_one)

  To attach generic controller metrics, call Exbox.Metrics.attach_controller_metrics/1 when starting your application
  with a relevant name:

      iex> def start(_type, _args) do
      iex>   Exbox.Metrics.attach_controller_metrics("myapp_endpoint_stop")

  If you want to attach metrics to other events, you can use Exbox.Metrics.attach_telemetry/2:

      iex> def start(_type, _args) do
      iex>   Exbox.Metrics.attach_telemetry(:my_event, [:my, :params])
  """
  alias Exbox.Metrics.MetricHandler

  @doc """
  Attaches metrics to the Phoenix endpoint stop event.

  Examples:

      iex> Exbox.Metrics.attach_controller_metrics
      :ok
  """
  @spec attach_controller_metrics() :: :ok
  def attach_controller_metrics do
    attach_telemetry(
      "phoenix_controller_metrics",
      [:phoenix, :endpoint, :stop],
      &MetricHandler.handle_event/4
    )
  end

  @doc """
  Attaches metrics to the given event with the given params.

  Examples:

      iex> Exbox.Metrics.attach_telemetry(:my_event, [:my, :params])
      :ok
  """
  @spec attach_telemetry(binary(), list(atom()), (any() -> any())) :: :ok
  def attach_telemetry(event, params, function) do
    if Application.get_env(:exbox, :capture_telemetry_events) do
      :ok =
        :telemetry.attach(
          event,
          params,
          function,
          nil
        )
    end
  end
end
