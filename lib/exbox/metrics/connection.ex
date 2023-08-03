defmodule Exbox.Metrics.Connection do
  @moduledoc """
  Connection for writing metrics to InfluxDB.
  """
  use Instream.Connection, otp_app: :exbox
end
