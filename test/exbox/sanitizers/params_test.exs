defmodule Exbox.Sanitizers.ParamsTest do
  use ExUnit.Case

  describe "sanitize/1" do
    test "sanitizes binary value with valid JSON" do
      value = %{"params" => "{\"password\":\"secret\",\"key\":\"value\"}"}
      expected = %{"params" => "{\"password\":\"[FILTERED]\",\"key\":\"[FILTERED]\"}"}
      assert Exbox.Sanitizers.Params.sanitize(value) == expected
    end

    test "sanitizes binary value with invalid JSON" do
      value = %{"params" => "invalid"}
      expected = %{"params" => "[FILTERED]"}
      assert Exbox.Sanitizers.Params.sanitize(value) == expected
    end

    test "sanitizes map value" do
      value = %{"params" => %{"key" => "value"}}
      assert Exbox.Sanitizers.Params.sanitize(value) == value
    end

    test "sanitizes list value" do
      value = %{"params" => ["key", "value"]}
      assert Exbox.Sanitizers.Params.sanitize(value) == value
    end

    test "sanitizes non-binary value" do
      value = %{"params" => %{"key" => "value"}}
      assert Exbox.Sanitizers.Params.sanitize(value) == value
    end
  end
end
