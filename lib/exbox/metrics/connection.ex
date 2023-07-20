defmodule Exbox.Metrics.Connection do
  @moduledoc """
  Connection for writing metrics to InfluxDB.
  """
  use Instream.Connection, opt_app: :exbox
end
