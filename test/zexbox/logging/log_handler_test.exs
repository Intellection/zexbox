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
               "LogHandler.handle_event/4 called with %{foo: \"bar\"}, %{fizz: \"buzz\"}, %{bar: \"foo\"} on stop"
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
               "LogHandler.handle_event/4 called with %{foo: \"bar\"}, %{fizz: \"buzz\"}, %{bar: \"foo\"} on start"
    end
  end
end
