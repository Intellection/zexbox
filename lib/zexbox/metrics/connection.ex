defmodule Zexbox.Metrics.Connection do
  @moduledoc """
  Connection for writing metrics to InfluxDB.
  """
  use Instream.Connection, otp_app: :zexbox
end
