defmodule ExboxTest do
  use ExUnit.Case
  doctest Exbox

  test "greets the world" do
    assert Exbox.hello() == :world
  end
end
