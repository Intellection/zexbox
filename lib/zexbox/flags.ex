defmodule Zexbox.Flags do
  @moduledoc """
  An Elixir wrapper around the LaunchDarkly Erlang client

  To start the client, call `Zexbox.Flags.start/2` when starting your application
  with a map of config options and an optional tag:

  ```elixir
  def start(_type, _args) do
    Zexbox.Flags.start()
    ...
  end
  ```

  To make sure that the client shuts down, you should call Zexbox.Flags.stop/1
  when your application shuts down:

  ```elixir
  def stop(_type, _args) do
    Zexbox.Flags.stop()
    ...
  end
  ```
  """

  @doc """
  Starts the LaunchDarkly client with the given config and tag.

  ## Examples

      iex> Zexbox.Flags.start(%{sdk_key: "my-sdk-key"}, :my_tag)
      :ok

      iex> Zexbox.Flags.start(%{sdk_key: "my-sdk-key"}, :my_tag)
      {:error, :already_started, #PID<0.602.0>}

  """
  @spec start(confi :: map(), tag :: atom()) :: :ok | {:error, atom(), term()}
  def start(%{sdk_key: sdk_key} = config, tag) do
    sdk_key
    |> String.to_charlist()
    |> :ldclient.start_instance(tag, parse_config(config))
  end

  @doc """
  Starts the LaunchDarkly client with the given config or the given tag.

  ## Examples

      iex> Zexbox.Flags.start(%{sdk_key: "my-sdk-key"})
      :ok
      iex> Zexbox.Flags.start(%{sdk_key: "my-sdk-key"})
      {:error, :already_started, #PID<0.602.0>}
      iex>

  """
  @spec start(tag :: atom()) :: :ok | {:error, atom(), term()}
  def start(tag) when is_atom(tag) do
    Application.fetch_env!(:zexbox, :flags)
    |> Enum.into(%{})
    |> start(tag)
  end

  @doc """
  Starts the LaunchDarkly client using the `:flags` application config and the `:default` tag.

  ## Examples

      iex> Zexbox.Flags.start()
      :ok
      iex> Zexbox.Flags.start()
      {:error, :already_started, #PID<0.602.0>}

  """
  @spec start() :: :ok | {:error, atom(), term()}
  def start,
    do: start(:default)

  @doc """
  Gets the variation of a flag for the given key, context, default value, and tag.

  ## Examples

      iex> Zexbox.Flags.variation("my-flag", %{key: "user-key"}, false, :my_tag)
      true

      iex> Zexbox.Flags.variation("my-flag", %{key: "user-key"}, false, :my_tag)
      {:error, {:not_found, "my-flag"}}

  """
  @spec variation(key :: String.t(), context :: map(), default :: any(), tag :: atom()) :: any()
  def variation(key, context, default, tag) do
    :ldclient.variation(key, :ldclient_context.new_from_map(context), default, tag)
  end

  @doc """
  Gets the variation of a flag for the given key, context, and default tag.

  ## Examples

      iex> Zexbox.Flags.variation("my-flag", %{key: "user-key"}, false)
      true

      iex> Zexbox.Flags.variation("my-flag", %{key: "user-key"}, false)
      {:error, {:not_found, "my-flag"}}

  """
  @spec variation(key :: String.t(), context :: map(), default :: any()) :: any()
  def variation(key, context_key, default), do: variation(key, context_key, default, :default)

  @doc """
  Stops the ldclient with the given tag.
  """
  @spec stop(tag :: atom()) :: :ok
  def stop(tag) do
    :ldclient.stop_instance(tag)
  end

  @doc """
  Stops the ldclient with the default tag.
  """
  @spec stop() :: :ok
  def stop, do: stop(:default)

  defp parse_config(config) do
    config
    |> Map.delete(:sdk_key)
    |> Map.merge(%{
      http_options: %{
        tls_options: :ldclient_config.tls_basic_options()
      }
    })
  end
end
