defmodule Zexbox.Logging.JsonHandlerTest do
  use ExUnit.Case, async: false

  alias Zexbox.Logging.JsonHandler

  setup do
    {:ok, original_config} = :logger.get_handler_config(:default)
    on_exit(fn -> :logger.update_handler_config(:default, original_config) end)
    :ok
  end

  describe "install!/1" do
    test "swaps the default handler's formatter to LoggerJSON.Formatters.Basic" do
      assert :ok = JsonHandler.install!()

      {:ok, %{formatter: {formatter_module, _config}}} =
        :logger.get_handler_config(:default)

      assert formatter_module == LoggerJSON.Formatters.Basic
    end

    test "passes metadata: :all by default" do
      assert :ok = JsonHandler.install!()

      {:ok, %{formatter: {_module, config}}} =
        :logger.get_handler_config(:default)

      assert config.metadata == :all
    end

    test "passes through a metadata allow-list" do
      assert :ok = JsonHandler.install!(metadata: [:request_id, :trace_id])

      {:ok, %{formatter: {_module, config}}} =
        :logger.get_handler_config(:default)

      assert config.metadata == [:request_id, :trace_id]
    end

    test "passes through redactors" do
      redactors = [{LoggerJSON.Redactors.RedactKeys, ["password"]}]
      assert :ok = JsonHandler.install!(redactors: redactors)

      {:ok, %{formatter: {_module, config}}} =
        :logger.get_handler_config(:default)

      assert config.redactors == redactors
    end

    test "is idempotent across repeated calls" do
      assert :ok = JsonHandler.install!()
      assert :ok = JsonHandler.install!()
      assert :ok = JsonHandler.install!(metadata: [:request_id])

      {:ok, %{formatter: {formatter_module, config}}} =
        :logger.get_handler_config(:default)

      assert formatter_module == LoggerJSON.Formatters.Basic
      assert config.metadata == [:request_id]
    end
  end

  describe "Zexbox.Logging.install_json_handler!/1 delegate" do
    test "the parent module exposes the same function" do
      assert :ok = Zexbox.Logging.install_json_handler!()

      {:ok, %{formatter: {formatter_module, _config}}} =
        :logger.get_handler_config(:default)

      assert formatter_module == LoggerJSON.Formatters.Basic
    end
  end
end
