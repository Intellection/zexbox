defmodule Zexbox do
  @moduledoc """
  Zexbox is a package containing common tooling and other functionality
  for Zappi's Elixir/Phoenix applications.
  It is the Elixir equivalent of the Opsbox, which was built for our Ruby/Rails stack.
  Supervisor for Zexbox.
  this exists to reduce the amount of boilerplate required to configure Zexbox.
  All GenServers, Supervisors and other processes for Zexbox should be started from here.
  It also has an entry point point for default opt-in by default functionality like attach_controller_metrics
  """
  use Supervisor

  @doc """
  Start the supervisor for Zexbox.
  """
  # credo:disable-for-next-line
  def start_link(_args) do
    start_state = Supervisor.start_link(__MODULE__, nil, name: :zexbox)
    default_opt_in_configurations()
    start_state
  end

  @doc """
  Initialise the supervisor for Zexbox. Set the children for the supervisor here.
  """
  # credo:disable-for-next-line
  def init(_args) do
    children = [
      Zexbox.Metrics.Connection
      # Add other child processes here if needed.
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp default_opt_in_configurations do
    Zexbox.Metrics.attach_controller_metrics()
    Zexbox.Logging.attach_controller_logs()
  end
end
