defmodule Exbox.Flags do
  @moduledoc """
  An Elixir wrapper around the LaunchDarkly Erlang client

  To use this module you must have the LaunchDarkly Erlang client installed.
  To do so, add {:ldclient, "~> 2.0.0", hex: :launchdarkly_server_sdk} to your
  list of dependencies in mix.exs.

  To start the client, call Exbox.Flags.start/2 when starting your application
  with a map of config options and an optional tag:

      iex> def start(_type, _args) do
      iex>   Exbox.Flags.start(%{sdk_key: "sdk-key", private_attributes: [:email]})

  To make sure that the client shuts down, you should call Exbox.Flags.stop/1
  when your application shuts down:

      iex> def stop(_state) do
      iex>   Exbox.Flags.stop()
  """

  @doc """
  Starts the LaunchDarkly client with the given config and tag.

  Examples:

        iex> Exbox.Flags.start(%{sdk_key: "sdk-key"}, :my_tag)
        :ok

        iex> Exbox.Flags.start(%{sdk_key: "sdk-key"}, :my_tag)
        {:error, {:already_started, #PID<0.602.0>}}
  """
  @spec start() :: :ok | {:error, atom(), term()}
  def start do
    Application.fetch_env!(:exbox, :flags)
    |> Enum.into(%{})
    |> start(:default)
  end

  @spec start(map(), atom()) :: :ok | {:error, atom(), term()}
  def start(%{sdk_key: sdk_key} = config, tag) do
    sdk_key
    |> String.to_charlist()
    |> :ldclient.start_instance(tag, parse_config(config))
  rescue
    # Well this is annoying. When attempting to start the LDclient twice it errors out rather
    # than returning a map of the form {:error, {:already_started, #PID<0.602.0>}} (which is the desired behaviour).
    # Having a look at the source code  shows that this is a known issue since there is just a TODO stating:
    # 'check if Tag already exists and return already_started error'.
    # The MatchError is a struct of the form %MatchError{term: {:error, {:already_started, #PID<0.602.0>}}
    # so we just return the 'term' attribute, giving us what we want.
    e in MatchError ->
      e.term
  end

  @spec start(map()) :: :ok | {:error, atom(), any()}
  def start(config), do: start(config, :default)

  @doc """
  Gets the variation of a flag for the given key, context, default value, and tag.

  Examples:

          iex> Exbox.Flags.variation("my-flag", %{key: "user-key"}, false, :my_tag)
          true

          iex> Exbox.Flags.variation("my-flag", %{key: "user-key"}, false, :my_tag)
          {:error, {:not_found, "my-flag"}}
  """
  @spec variation(String.t(), map(), any(), atom()) :: any()
  def variation(key, context, default, tag) do
    :ldclient.variation(key, :ldclient_context.new_from_map(context), default, tag)
  end

  @spec variation(String.t(), map(), any()) :: any()
  def variation(key, context_key, default), do: variation(key, context_key, default, :default)

  @spec stop(atom()) :: :ok
  def stop(tag) do
    :ldclient.stop_instance(tag)
  end

  @spec stop() :: :ok
  def stop, do: stop(:default)

  defp parse_config(config) do
    config
    |> Map.delete(:sdk_key)
    |> Map.update(:file_paths, [], fn paths -> Enum.map(paths, &String.to_charlist/1) end)
  end
end
