defmodule Zexbox.Metrics.MetricHandlerTest do
  use ExUnit.Case
  alias Zexbox.Metrics.{ControllerSeries, MetricHandler}

  defmodule MockClient do
    @spec write_metric(ControllerSeries.t()) :: ControllerSeries.t()
    def write_metric(metric) do
      metric
    end
  end

  test "handle_event/4" do
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

    expected = %ControllerSeries{
      fields: %Zexbox.Metrics.ControllerSeries.Fields{
        count: 1,
        trace_id: "trace_id",
        duration_ms: 1000,
        http_referer: "https://www.google.com",
        path: "/",
        request_id: nil,
        success: 1.0
      },
      tags: %Zexbox.Metrics.ControllerSeries.Tags{
        action: "index",
        controller: "page_controller",
        format: "html",
        method: "GET",
        status: 200
      }
    }

    assert MetricHandler.handle_event(
             [:phoenix, :endpoint, :stop],
             measurements,
             metadata,
             config
           ) == expected
  end
end
