defmodule Zexbox do
  @moduledoc """
  The Zexbox Supervisor module.

  This needs to be to your applicaiton's supervisor tree in order to enable metrics and logging in
  your Phoenix controllers.
  """
  use Supervisor

  @doc """
  Start the supervisor for Zexbox.
  """
  @spec start_link(args :: any()) :: Supervisor.on_start()
  def start_link(_args) do
    start_state = Supervisor.start_link(__MODULE__, nil, name: :zexbox)
    default_opt_in_configurations()
    start_state
  end

  @doc """
  Initialise the supervisor for Zexbox.
  """
  @impl Supervisor
  def init(_args) do
    children = [
      Zexbox.Metrics.Connection
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp default_opt_in_configurations do
    Zexbox.Metrics.attach_controller_metrics()
    Zexbox.Logging.attach_controller_logs()
  end
end
