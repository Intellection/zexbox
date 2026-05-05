defmodule Zexbox.Logging.JsonFormatterTest do
  use ExUnit.Case, async: true

  alias Zexbox.Logging.JsonFormatter

  describe "config/1" do
    test "returns LoggerJSON.Formatters.Basic with sensible defaults" do
      assert {LoggerJSON.Formatters.Basic, opts} = JsonFormatter.config()
      assert :request_id in opts.metadata
      assert :user_id in opts.metadata
      refute opts.redactors == []
    end

    test "metadata override is honoured" do
      assert {_module, %{metadata: [:foo, :bar]}} =
               JsonFormatter.config(metadata: [:foo, :bar])
    end

    test "redactors override is honoured" do
      assert {_module, %{redactors: []}} = JsonFormatter.config(redactors: [])
    end

    test "default lists are exposed for inspection" do
      assert :request_id in JsonFormatter.default_metadata()
      assert [{LoggerJSON.Redactors.RedactKeys, _keys}] = JsonFormatter.default_redactors()
    end
  end

  describe "Zexbox.Logging.json_formatter_config/1 delegate" do
    test "returns the same config" do
      assert Zexbox.Logging.json_formatter_config() == JsonFormatter.config()
    end
  end
end
