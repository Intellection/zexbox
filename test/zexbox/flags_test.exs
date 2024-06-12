defmodule Zexbox.FlagsTest do
  use ExUnit.Case
  import Mock
  alias Zexbox.Flags
  require Logger

  @config %{
    sdk_key: "sdk-key",
    feature_store: :ldclient_storage_map,
    send_events: false,
    file_datasource: true,
    file_paths: ["test/feature_flags/flags.json"],
    file_auto_update: true
  }

  setup do
    Application.put_env(:zexbox, :flags, @config)
    on_exit(fn -> Application.delete_env(:zexbox, :flags) end)
  end

  test_with_mock "start/0", :ldclient,
    start_instance: fn ~c"sdk-key",
                       :default,
                       %{
                         feature_store: :ldclient_storage_map,
                         send_events: false,
                         file_datasource: true,
                         file_paths: ["test/feature_flags/flags.json"],
                         file_auto_update: true
                       } ->
      :ok
    end do
    assert :ok = Flags.start()
  end

  test_with_mock "stop/0", :ldclient, stop_instance: fn :default -> :ok end do
    assert :ok = Flags.stop()
  end

  # :ldclient.variation(key, :ldclient_context.new_from_map(context), default, tag)

  test_with_mock "variation/4", :ldclient,
    variation: fn "my-flag", %{}, "default", :default ->
      :ok
    end do
    assert :ok = Flags.variation("my-flag", %{}, "default")
  end
end
