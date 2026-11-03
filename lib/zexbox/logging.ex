defmodule Zexbox.Logging do
  @moduledoc """
  Module for logging events in Zexbox.
  """

  alias Zexbox.Logging.{JsonFormatter, LogHandler}
  alias Zexbox.Telemetry

  if Code.ensure_loaded?(LoggerJSON) do
    @doc """
    Returns a JSON `:logger` formatter with Zappi defaults, for use in `config/runtime.exs`.
    Requires the optional `:logger_json` dependency:

        config :logger, :default_handler,
          formatter: Zexbox.Logging.json_formatter_config()

    See `Zexbox.Logging.JsonFormatter.config/1` for options.
    """
    @spec json_formatter_config(keyword()) :: {module(), map()}
    defdelegate json_formatter_config(opts \\ []), to: JsonFormatter, as: :config
  end

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
