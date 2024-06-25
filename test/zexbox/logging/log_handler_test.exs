defmodule Zexbox.Logging.LogHandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Zexbox.Logging.LogHandler

  describe "handle_event/4" do
    test "returns :ok for stop event" do
      assert capture_log(fn ->
               LogHandler.handle_event(
                 [:phoenix, :endpoint, :stop],
                 %{foo: "bar"},
                 %{fizz: "buzz"},
                 %{bar: "foo"}
               )
             end) =~
               "[info] [event: [:phoenix, :endpoint, :stop], measurements: %{foo: \"bar\"}, metadata: %{fizz: \"buzz\"}, config: %{bar: \"foo\"}]"
    end

    test "returns :ok for start event" do
      assert capture_log(fn ->
               LogHandler.handle_event(
                 [:phoenix, :endpoint, :start],
                 %{foo: "bar"},
                 %{fizz: "buzz"},
                 %{bar: "foo"}
               )
             end) =~
               "[info] [event: [:phoenix, :endpoint, :start], measurements: %{foo: \"bar\"}, metadata: %{fizz: \"buzz\"}, config: %{bar: \"foo\"}]"
    end
  end
end
