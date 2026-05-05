defmodule Zexbox.Logging do
  @moduledoc """
  Module for logging events in Zexbox.
  """

  alias Zexbox.Logging.{JsonFormatter, LogHandler}
  alias Zexbox.Telemetry

  @doc """
  Returns a `:logger` formatter tuple wrapping `LoggerJSON.Formatters.Basic`
  with Zappi-standard defaults. Designed to be splatted into
  `config :logger, :default_handler, formatter: ...` in `config/runtime.exs`:

      if config_env() == :prod do
        config :logger, :default_handler,
          formatter: Zexbox.Logging.json_formatter_config()
      end

  Mirrors opsbox's Ruby-side `JsonFormatter`: every log event becomes one
  JSON object on one line, so multi-line content (struct inspections,
  multi-line SQL, stack traces) collapses into a single Elasticsearch
  document at the ingest layer.

  See `Zexbox.Logging.JsonFormatter` for the full option list.
  """
  @spec json_formatter_config(keyword()) :: {module(), map()}
  defdelegate json_formatter_config(opts \\ []), to: JsonFormatter, as: :config

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
