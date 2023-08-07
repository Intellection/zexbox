defmodule Exbox.Logging.LogHandler do
  def handle_event([:phoenix, :endpoint, :stop], measurements, metadata, config) do
    IO.puts(
      "LogHandler.handle_event/4 called with #{inspect(measurements)}, #{inspect(metadata)}, #{inspect(config)} on stop"
    )

    :ok
  end

  def handle_event([:phoenix, :endpoint, :start], measurements, metadata, config) do
    IO.puts(
      "LogHandler.handle_event/4 called with #{inspect(measurements)}, #{inspect(metadata)}, #{inspect(config)} on start"
    )

    :ok
  end
end
