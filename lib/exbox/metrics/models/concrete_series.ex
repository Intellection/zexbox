defmodule Exbox.Metrics.Models.ConcreteSeries do
  @behaviour Instream.Series

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro series(do_block) do
    quote do
      use Instream.Series

      @series_definition %{
        measurement: "",
        tags: %{},
        fields: %{}
      }

      unquote(do_block)
    end
  end

  defmacro default_series(do_block) do
    quote do
      @series_definition %{
        measurement: "",
        tags: %{},
        fields: %{}
      }

      unquote(do_block)
    end
  end
end
