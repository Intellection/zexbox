defmodule Zexbox.FlagsTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Zexbox.Flags
  require Logger

  defp start_client(tag) do
    :ldclient.start_instance(~c"sdk-key", tag, %{
      file_datasource: true,
      send_events: false,
      file_auto_update: true,
      feature_store: :ldclient_storage_map,
      file_paths: [~c"test/features/flags.json"]
    })
  end

  defp stop_client(tag) do
    :ldclient.stop_instance(tag)
  end

  setup_all do
    tag = :feature_flags_test

    start_client(tag)
    on_exit(fn -> stop_client(tag) end)

    config_map = %{
      sdk_key: "sdk-key",
      file_datasource: true,
      send_events: false,
      file_auto_update: true,
      feature_store: :ldclient_storage_map,
      file_paths: ["test/feature_flags/flags.json"]
    }

    %{config_map: config_map, tag: tag}
  end

  describe "Flags.start/1" do
    test "when no ldclient instance has been started", %{config_map: config_map, tag: tag} do
      # Need to stop the client here first
      stop_client(tag)
      assert :ok == Flags.start(config_map, tag)
    end

    test "when an ldclient instance has already been started", %{config_map: config_map, tag: tag} do
      assert {:error, :already_started, _pid} = Flags.start(config_map, tag)
    end
  end

  describe "Flags.variation/4" do
    # test "when flag exists", %{tag: tag} do
    #   Process.sleep(300)

    #   assert Flags.variation(
    #            "dummy-flag",
    #            %{key: "context-key"},
    #            "a-default",
    #            tag
    #          ) == 190
    # end

    test "when flag doesn't exist", %{tag: tag} do
      Process.sleep(200)

      {result, _warning} =
        with_log(fn ->
          Flags.variation(
            "foo",
            %{key: "context-key"},
            "a-default",
            tag
          )
        end)

      assert result == "a-default"
    end
  end

  test "Flags.stop/1", %{tag: tag} do
    assert :ok == Flags.stop(tag)
    assert :ok == start_client(tag)
  end
end
