defmodule Zexbox.Logging.LogHandler do
  @moduledoc """
  Handles the default start and stop events for phoenix endpoints. This makes use of the
  default [Logger](https://hexdocs.pm/logger/main/Logger.html) module and as such will obey the :logger configuration
  specified in your app.
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
