defmodule Zexbox.MetricsTest do
  use ExUnit.Case
  alias Zexbox.Metrics

  defmodule EchoEnricher do
    @behaviour Zexbox.Metrics.ControllerSeriesEnricher
    @impl true
    def init(opts), do: {:initialised, opts}
    @impl true
    def call(series, _conn, _opts), do: series
  end

  setup do
    on_exit(fn ->
      :telemetry.detach("phoenix_controller_metrics")

      try do
        Supervisor.stop(Metrics)
      catch
        :exit, _ -> :ok
      end
    end)

    :ok
  end

  test "start_link/1 starts the metrics supervisor" do
    {:ok, pid} = Metrics.start_link(nil)
    assert Process.alive?(pid)
  end

  test "start_link/1 normalises the enricher option through its init/1" do
    {:ok, _pid} = Metrics.start_link(enricher: {EchoEnricher, [foo: :bar]})

    handler =
      [:phoenix, :endpoint, :stop]
      |> :telemetry.list_handlers()
      |> Enum.find(&(&1.id == "phoenix_controller_metrics"))

    assert handler.config == %{enricher: {EchoEnricher, {:initialised, [foo: :bar]}}}
  end

  test "init/1 initializes the metrics supervisor" do
    assert {:ok,
            {%{intensity: 3, period: 5, strategy: :one_for_one, auto_shutdown: :never},
             [
               %{
                 id: Zexbox.Metrics.ContextRegistry,
                 start: {Zexbox.Metrics.ContextRegistry, :start_link, [[]]}
               },
               %{
                 id: Zexbox.Metrics.Connection,
                 start: {Instream.Connection.Supervisor, :start_link, [Zexbox.Metrics.Connection]}
               }
             ]}} = Metrics.init(nil)
  end
end
