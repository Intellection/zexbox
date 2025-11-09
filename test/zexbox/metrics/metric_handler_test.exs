defmodule Zexbox.Metrics.MetricHandlerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  alias Zexbox.Metrics.{ControllerSeries, MetricHandler}

  defmodule MockClient do
    @spec write_metric(ControllerSeries.t()) :: ControllerSeries.t()
    def write_metric(metric) do
      metric
    end
  end

  describe "handle_event/4" do
    setup do
      event = [:phoenix, :endpoint, :stop]

      measurements = %{duration: 1_000_000_000}

      metadata = %{
        conn: %{
          status: 200,
          method: "GET",
          private: %{
            phoenix_action: :index,
            phoenix_format: "html",
            phoenix_controller: :page_controller
          },
          assigns: %{
            trace_id: "trace_id"
          },
          request_path: "/",
          req_headers: [{"referer", "https://www.google.com"}]
        }
      }

      config = %{metric_client: MockClient}

      {:ok, [event: event, measurements: measurements, metadata: metadata, config: config]}
    end

    test "creates the expected ControllerSeries on success", %{
      event: event,
      measurements: measurements,
      metadata: metadata,
      config: config
    } do
      assert %ControllerSeries{
               fields: %ControllerSeries.Fields{
                 count: 1,
                 trace_id: "trace_id",
                 duration_ms: 1000,
                 http_referer: "https://www.google.com",
                 path: "/",
                 request_id: nil,
                 success: 1.0
               },
               tags: %ControllerSeries.Tags{
                 action: "index",
                 controller: "page_controller",
                 format: "html",
                 method: "GET",
                 status: 200
               }
             } ==
               MetricHandler.handle_event(
                 event,
                 measurements,
                 metadata,
                 config
               )
    end

    test "does not write the metric if the phoenix_ values are missing from conn.private ", %{
      event: event,
      measurements: measurements,
      config: config
    } do
      metadata = %{
        conn: %{
          status: 200,
          method: "GET",
          private: %{},
          request_path: "/",
          req_headers: []
        }
      }

      assert MetricHandler.handle_event(
               event,
               measurements,
               metadata,
               config
             ) == nil
    end

    test "captures and logs any exceptions", %{event: event, metadata: metadata} do
      assert capture_log(fn ->
               MetricHandler.handle_event(event, nil, metadata, nil)
             end) =~ "Exception creating controller series: %BadMapError"
    end
  end
end
