defmodule Zexbox.Metrics.ContextTest do
  use ExUnit.Case

  alias Zexbox.Metrics.{Context, ContextRegistry}

  describe "disable_for_process/0 and enable_for_process/0" do
    setup do
      start_supervised!(ContextRegistry)

      old_callers = Process.get(:"$callers")
      old_ancestors = Process.get(:"$ancestors")

      on_exit(fn ->
        Process.put(:"$callers", old_callers)
        Process.put(:"$ancestors", old_ancestors)
      end)

      :ok
    end

    test "toggles disabled? for the current process" do
      assert Context.disabled?() == false

      :ok = Zexbox.Metrics.disable_for_process()
      assert Context.disabled?() == true
      assert Context.metrics_disabled?() == true

      :ok = Zexbox.Metrics.enable_for_process()
      assert Context.disabled?() == false
      assert Context.metrics_disabled?() == false
    end

    test "inherits disabled state through Task caller chain" do
      :ok = Zexbox.Metrics.disable_for_process()

      task =
        Task.async(fn ->
          Context.metrics_disabled?()
        end)

      assert Task.await(task) == true

      :ok = Zexbox.Metrics.enable_for_process()
    end

    test "metrics_disabled?/0 tolerates nested $callers and non-pid terms" do
      parent = self()

      pid =
        spawn(fn ->
          send(parent, :ready)

          receive do
            :stop -> :ok
          end
        end)

      on_exit(fn -> send(pid, :stop) end)
      assert_receive :ready

      :ok = ContextRegistry.register(pid)

      # Simulate unexpected shapes (nested lists, tuples, etc.) in the process dictionary.
      Process.put(:"$callers", [[pid], {:not_a_pid, 123}])
      Process.put(:"$ancestors", [[:some_name], [pid]])

      assert Context.metrics_disabled?() == true
    end

    test "metrics_disabled?/0 tolerates atom ancestors" do
      Process.put(:"$ancestors", [:some_registered_name])
      assert Context.metrics_disabled?() == false
    end
  end
end
