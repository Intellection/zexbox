defmodule Zexbox.Metrics.Connection do
  @moduledoc """
  Connection for writing metrics to InfluxDB.
  """
  use Instream.Connection,
    otp_app: :zexbox,
    config: [http_client: Zexbox.Metrics.HTTPClient]
end
