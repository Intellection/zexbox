defmodule Zexbox.Logging.JsonFormatterTest do
  use ExUnit.Case, async: true

  alias LoggerJSON.Formatters.Basic
  alias Zexbox.Logging.JsonFormatter

  doctest JsonFormatter

  defp format(formatter, msg, meta) do
    {module, config} = formatter

    event = %{
      level: :info,
      msg: {:string, msg},
      meta: Map.merge(%{time: System.os_time(:microsecond)}, meta)
    }

    module.format(event, config) |> IO.iodata_to_binary()
  end

  defp decode_metadata(line), do: Jason.decode!(line)["metadata"]

  describe "config/1" do
    test "options replace the defaults for their key only" do
      assert JsonFormatter.config(redactors: []) ==
               Basic.new(metadata: JsonFormatter.default_metadata(), redactors: [])
    end

    test "passes other Basic options through" do
      {Basic, config} = JsonFormatter.config(encoder_opts: [pretty: true])

      assert config.encoder_opts == [pretty: true]
    end
  end

  describe "formatting with the defaults" do
    test "writes a multi-line message as one line of JSON" do
      line = format(JsonFormatter.config(), "first\nsecond", %{})

      assert [json, ""] = String.split(line, "\n")
      assert Jason.decode!(json)["message"] == "first\nsecond"
    end

    test "includes the request, call site and process metadata Logger sets" do
      meta = %{
        request_id: "abc",
        user_id: 42,
        application: :zexbox,
        mfa: {MyApp.Thing, :run, 2},
        file: "lib/my_app/thing.ex",
        line: 12,
        pid: self()
      }

      metadata = decode_metadata(format(JsonFormatter.config(), "hello", meta))

      assert metadata["request_id"] == "abc"
      assert metadata["user_id"] == 42
      assert metadata["application"] == "zexbox"
      assert metadata["mfa"] == "Elixir.MyApp.Thing.run/2"
      assert metadata["file"] == "lib/my_app/thing.ex"
      assert metadata["line"] == 12
      assert is_binary(metadata["pid"])
    end

    test "drops metadata outside the allow-list" do
      metadata = decode_metadata(format(JsonFormatter.config(), "hello", %{other: "x"}))

      refute Map.has_key?(metadata, "other")
    end

    test "redacts credential keys" do
      meta = %{access_token: "t", Authorization: "Bearer t", password: "hunter2"}
      formatter = JsonFormatter.config(metadata: Map.keys(meta))

      metadata = decode_metadata(format(formatter, "hello", meta))

      assert metadata == %{
               "access_token" => "[REDACTED]",
               "Authorization" => "[REDACTED]",
               "password" => "[REDACTED]"
             }
    end
  end

  test "Zexbox.Logging.json_formatter_config/1 delegates to config/1" do
    assert Zexbox.Logging.json_formatter_config(redactors: []) ==
             JsonFormatter.config(redactors: [])
  end
end
