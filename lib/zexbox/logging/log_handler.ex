defmodule Zexbox.Logging.LogHandler do
  @moduledoc """
  Handles all log events
  """
  require Logger

  @doc """
  This function is called by the Phoenix endpoint when a controller action is
  started and finished.

  This allows us to use kibana for log inspection and monitoring

  ## Examples

      iex> Zexbox.Logging.LogHandler.handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config)
      :ok

  """
  @spec handle_event(list(atom), map(), map(), map()) :: :ok
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    Logger.log(
      :info,
      "LogHandler.handle_event/4 called with #{inspect(measurements)}, #{inspect(metadata)}, #{inspect(config)} on stop"
    )
  end

  def handle_event([:phoenix, :endpoint, :start], measurements, metadata, config) do
    Logger.log(
      :info,
      "LogHandler.handle_event/4 called with #{inspect(measurements)}, #{inspect(metadata)}, #{inspect(config)} on start"
    )
  end
end
