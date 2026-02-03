defmodule Zexbox.Metrics.ContextRegistryTest do
  use ExUnit.Case

  alias Zexbox.Metrics.ContextRegistry

  describe "register/1, unregister/1, disabled?/1" do
    setup do
      # Start a supervised ContextRegistry for each test
      # This ensures a clean state and proper cleanup
      start_supervised!(ContextRegistry)
      :ok
    end
    test "registers and unregisters a pid" do
      pid = self()

      assert ContextRegistry.disabled?(pid) == false

      :ok = ContextRegistry.register(pid)
      assert ContextRegistry.disabled?(pid) == true

      :ok = ContextRegistry.unregister(pid)
      assert ContextRegistry.disabled?(pid) == false
    end

    test "cleans up disabled pid when it exits" do
      parent = self()

      pid =
        spawn(fn ->
          send(parent, :ready)

          receive do
            :stop -> :ok
          end
        end)

      assert_receive :ready

      :ok = ContextRegistry.register(pid)
      assert ContextRegistry.disabled?(pid) == true

      send(pid, :stop)

      # Wait until the registry processes the :DOWN and removes ETS entry.
      eventually(fn -> ContextRegistry.disabled?(pid) == false end)
    end
  end

  defp eventually(predicate, attempts \\ 50)

  defp eventually(predicate, 0) do
    assert predicate.()
  end

  defp eventually(predicate, attempts) do
    if predicate.() do
      :ok
    else
      Process.sleep(5)
      eventually(predicate, attempts - 1)
    end
  end
end
