defmodule Exbox.Logging.LogHandlerTest do
  use ExUnit.Case

  import Exbox.Logging.LogHandler

  describe "handle_event/4" do
    test "returns :ok for stop event" do
      result = handle_event([:phoenix, :endpoint, :stop], %{}, %{}, %{})
      assert result == :ok
    end

    test "returns :ok for start event" do
      result = handle_event([:phoenix, :endpoint, :start], %{}, %{}, %{})
      assert result == :ok
    end
  end
end
