defmodule Zexbox.Telemetry do
  @moduledoc """
  A (very) thin wrapper around the :telemetry erlang module
  """

  @doc """
  Attaches the given handler to the specified event.

  see :telemetry.attach/4 for more information

  ## Examples

      iex> Zexbox.Telemetry.attach(:my_event, [:my, :event], &MyAppHandler.my_handler/3, nil)
      :ok

  """

  @type event_name :: any()
  @type event_params :: [atom() | :stop]
  @type callback ::
          (event_name(),
           event_measurements :: map(),
           event_metadata :: map(),
           handler_config :: any() ->
             any())
  @type config :: any()

  @spec attach(event_name(), event_params(), callback(), config()) ::
          :ok | {:error, :already_exists}
  def attach(event, params, function, config) do
    :telemetry.attach(event, params, function, config)
  end
end
