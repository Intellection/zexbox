defmodule Zexbox.Logging.LogHandler do
  @moduledoc """
  Handles all log events. This uses the default Logger module to log events to the console.
  """
  require Logger

  @doc """
  This function is called by the Phoenix endpoint when a controller action is started or finished.

  ## Examples

      iex> Zexbox.Logging.LogHandler.handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config)
      :ok

  """
  @spec handle_event(list(atom), map(), map(), map()) :: :ok
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    Logger.info(
      event: [:phoenix, :endpoint, :stop],
      measurements: measurements,
      metadata: metadata,
      config: config
    )
  end

  def handle_event([:phoenix, :endpoint, :start], measurements, metadata, config) do
    Logger.info(
      event: [:phoenix, :endpoint, :start],
      measurements: measurements,
      metadata: metadata,
      config: config
    )
  end
end
