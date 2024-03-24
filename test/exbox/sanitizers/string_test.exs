defmodule Exbox.Sanitizers.StringTest do
  use ExUnit.Case

  describe "sanitize/1" do
    test "sanitizes binary value with filter key" do
      value = "key=value&password=secret"
      expected = "key=[FILTERED]&password=[FILTERED]"
      assert Exbox.Sanitizers.String.sanitize(value) == expected
    end

    test "sanitizes binary value without filter key" do
      value = "other=value"
      assert Exbox.Sanitizers.String.sanitize(value) == value
    end

    test "doesn't sanitize non-binary value" do
      value = %{"key" => "value"}
      assert Exbox.Sanitizers.String.sanitize(value) == value
    end
  end
end
