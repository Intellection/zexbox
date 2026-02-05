defmodule Zexbox.Metrics.ContextRegistry do
  @moduledoc """
  GenServer that maintains an ETS set of PIDs for which metrics are disabled.
  Monitors registered PIDs and removes them on :DOWN to prevent leaks.
  """

  use GenServer

  @table :zexbox_metrics_disabled_pids

  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    case GenServer.start_link(__MODULE__, opts, name: __MODULE__) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      other -> other
    end
  end

  @doc """
  Registers the given pid as disabled for metrics. The pid is monitored
  so the entry is removed when the process exits.
  """
  @spec register(pid()) :: :ok
  def register(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:register, pid})
  end

  @doc """
  Removes the given pid from the disabled set.
  """
  @spec unregister(pid()) :: :ok
  def unregister(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:unregister, pid})
  end

  @doc """
  Returns true if the given pid is in the disabled set.
  """
  @spec disabled?(pid() | atom() | nil) :: boolean()
  def disabled?(pid) when is_pid(pid) or is_atom(pid) do
    case :ets.lookup(@table, pid) do
      [{^pid, _present}] -> true
      [] -> false
    end
  end

  def disabled?(_pid), do: false

  @impl GenServer
  def init(_opts) do
    _table = :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    {:ok, %{ref_to_pid: %{}, pid_to_ref: %{}}}
  end

  @impl GenServer
  def handle_call({:register, pid}, _from, state) do
    if Map.has_key?(state.pid_to_ref, pid) do
      {:reply, :ok, state}
    else
      ref = Process.monitor(pid)
      :ets.insert(@table, {pid, true})
      ref_to_pid = Map.put(state.ref_to_pid, ref, pid)
      pid_to_ref = Map.put(state.pid_to_ref, pid, ref)
      {:reply, :ok, %{ref_to_pid: ref_to_pid, pid_to_ref: pid_to_ref}}
    end
  end

  @impl GenServer
  def handle_call({:unregister, pid}, _from, state) do
    case Map.pop(state.pid_to_ref, pid) do
      {nil, _pid_to_ref} ->
        {:reply, :ok, state}

      {ref, pid_to_ref} ->
        Process.demonitor(ref, [:flush])
        :ets.delete(@table, pid)
        ref_to_pid = Map.delete(state.ref_to_pid, ref)
        {:reply, :ok, %{ref_to_pid: ref_to_pid, pid_to_ref: pid_to_ref}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, ref, _type, _pid, _reason}, state) do
    case Map.pop(state.ref_to_pid, ref) do
      {nil, _ref_to_pid} ->
        {:noreply, state}

      {pid, ref_to_pid} ->
        :ets.delete(@table, pid)
        pid_to_ref = Map.delete(state.pid_to_ref, pid)
        {:noreply, %{ref_to_pid: ref_to_pid, pid_to_ref: pid_to_ref}}
    end
  end
end
