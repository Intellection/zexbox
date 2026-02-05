defmodule Zexbox.Metrics.Context do
  @moduledoc """
  Per-process context for metrics: disable/enable and caller-chain checks.
  Used by `Zexbox.Metrics.Client` to skip writes when the current process
  or a parent (e.g. request process) has disabled metrics.
  """

  alias Zexbox.Metrics.ContextRegistry

  @doc """
  Disables metric writing for the current process. Writes from this process
  (and from tasks spawned with `Task.async` that have this process in `$callers`)
  will be skipped until `enable_for_process/0` is called or the process exits.
  """
  @spec disable_for_process() :: :ok
  def disable_for_process do
    ContextRegistry.register(self())
  end

  @doc """
  Re-enables metric writing for the current process.
  """
  @spec enable_for_process() :: :ok
  def enable_for_process do
    ContextRegistry.unregister(self())
  end

  @doc """
  Returns true if the current process has disabled metrics.
  """
  @spec disabled?() :: boolean()
  def disabled? do
    ContextRegistry.disabled?(self())
  end

  @doc """
  Returns true if metrics should be skipped for the current process: either
  the process itself has disabled metrics, or any process in its caller chain
  (`$callers` or `$ancestors`) has disabled metrics.
  """
  @spec metrics_disabled?() :: boolean()
  def metrics_disabled? do
    ([self()] ++ callers() ++ ancestors())
    |> List.flatten()
    |> Enum.filter(&(is_pid(&1) or is_atom(&1)))
    |> Enum.any?(&ContextRegistry.disabled?/1)
  end

  defp callers do
    case Process.get(:"$callers") do
      nil -> []
      list when is_list(list) -> list
    end
  end

  defp ancestors do
    case Process.get(:"$ancestors") do
      nil -> []
      list when is_list(list) -> list
    end
  end
end
