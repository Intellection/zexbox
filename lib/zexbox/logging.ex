defmodule Zexbox.Logging do
  @moduledoc """
  Module for logging events in Zexbox.
  """

  alias Zexbox.Logging.JsonHandler
  alias Zexbox.Logging.LogHandler
  alias Zexbox.Telemetry

  @doc """
  Installs a JSON formatter on the default `:logger` handler so every
  log event is emitted as a single JSON line.

  Designed to mirror the behaviour of opsbox's `JsonFormatter` on the Ruby
  side. Multi-line content (Elixir struct inspections, multi-line SQL,
  stack traces) collapses into a single Elasticsearch document at the
  ingest layer rather than fanning out into many.

  Typical usage in `config/runtime.exs`:

      if config_env() == :prod do
        Zexbox.Logging.install_json_handler!()
      end

  See `Zexbox.Logging.JsonHandler` for the full option list.
  """
  @spec install_json_handler!(keyword()) :: :ok | {:error, term()}
  defdelegate install_json_handler!(opts \\ []), to: JsonHandler, as: :install!

  @doc """
  Attaches Telemetry handlers for Phoenix controller events.

  This function sets up handlers for the `[:phoenix, :endpoint, :stop]` and `[:phoenix, :endpoint, :start]` events.
  The handlers are named `"phoenix_controller_logs_stop"` and `"phoenix_controller_logs_start"`,
  both of which use the `LogHandler.handle_event/4` function to process the events.

  ## Examples

      iex> Logging.attach_controller_logs()
      :ok
      iex> Logging.attach_controller_logs()
      ** (RuntimeError) event already exists

  """
  @spec attach_controller_logs!() :: :ok
  def attach_controller_logs! do
    stop_result =
      Telemetry.attach(
        "phoenix_controller_logs_stop",
        [:phoenix, :endpoint, :stop],
        &LogHandler.handle_event/4,
        nil
      )

    start_result =
      Telemetry.attach(
        "phoenix_controller_logs_start",
        [:phoenix, :endpoint, :start],
        &LogHandler.handle_event/4,
        nil
      )

    case {stop_result, start_result} do
      {:ok, :ok} -> :ok
      _error -> raise "Phoenix controller logs already attached"
    end
  end
end
