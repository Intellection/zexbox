defmodule Exbox.Supervisor do
  use Supervisor

  @moduledoc """
    Supervisor for Exbox.
    this exists to reduce the amount of boilerplate required to configure Exbox.
    All GenServers, Supervisors and other processes for Exbox should be started from here.
    It also has an entry point point for default opt-in by default functionality like attach_controller_metrics
  """
  def start_link(args) do
    start_state = Supervisor.start_link(__MODULE__, nil, name: :exbox)
    default_opt_in_configurations()
    start_state
  end

  def init(_args) do
    children = [
      Exbox.Config,
      Exbox.Metrics.Connection
      # Add other child processes here if needed.
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def default_opt_in_configurations do
    Exbox.Metrics.attach_controller_metrics()
    Exbox.Logging.attach_controller_logs()
  end
end
