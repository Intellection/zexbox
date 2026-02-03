defmodule Zexbox.Metrics.ContextTest do
  use ExUnit.Case

  alias Zexbox.Metrics.Context

  setup_all do
    ensure_registry_started()
    :ok
  end

  describe "disable_for_process/0 and enable_for_process/0" do
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
  end

  defp ensure_registry_started do
    case Process.whereis(Zexbox.Metrics.ContextRegistry) do
      nil -> {:ok, _pid} = Zexbox.Metrics.ContextRegistry.start_link()
      _pid -> :ok
    end
  end
end

