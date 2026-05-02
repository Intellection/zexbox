defmodule Zexbox.Logging.JsonHandler do
  @moduledoc """
  Replaces the default `:logger` handler's formatter with a JSON formatter
  suitable for Logstash / Elasticsearch ingestion.

  Emits one JSON object per line, so multi-line content (Elixir struct
  inspections, multi-line SQL, stack traces) collapses into a single log
  event at the ingest layer instead of fanning out into N separate
  Elasticsearch documents.

  This is the Phoenix / Elixir equivalent of opsbox's `JsonFormatter` for Ruby.
  Wraps `LoggerJSON.Formatters.Basic` with sensible defaults for the
  Zappi log-ingest pipeline.

  ## Setup

  In your application's `config/runtime.exs`:

      if config_env() == :prod do
        Zexbox.Logging.JsonHandler.install!()
      end

  After install, every log line is a single JSON object:

      {"time":"...","severity":"info","message":"...","metadata":{...}}

  Logstash's existing `kubernetes.container.name` rules can then JSON-parse
  these into structured fields the same way they do for opsbox-formatted
  Ruby logs.

  ## Options

    * `:metadata` - which `Logger` metadata keys to include. Defaults to
      `:all` (every key set via `Logger.metadata/1` or
      `Logger.put_application_level/2`). Pass a list (e.g.
      `[:request_id, :trace_id]`) to filter, or `[]` to omit metadata.

    * `:redactors` - a list of `LoggerJSON.Redactor` modules applied to
      metadata values before serialisation, e.g. for stripping sensitive
      keys. Defaults to `[]`.

  ## Idempotency

  Safe to call multiple times — `install!/1` simply swaps the formatter
  on the existing default handler. Subsequent calls overwrite the previous
  formatter config.
  """

  @doc """
  Install the JSON formatter on the `:default` `:logger` handler.

  Returns `:ok` on success or `{:error, reason}` if the default handler
  hasn't been configured (typically only in unusual test setups).

  ## Examples

      iex> Zexbox.Logging.JsonHandler.install!()
      :ok

      iex> Zexbox.Logging.JsonHandler.install!(metadata: [:request_id, :trace_id])
      :ok
  """
  @spec install!(keyword()) :: :ok | {:error, term()}
  def install!(opts \\ []) do
    formatter_config = %{
      metadata: Keyword.get(opts, :metadata, :all),
      redactors: Keyword.get(opts, :redactors, [])
    }

    :logger.update_handler_config(
      :default,
      :formatter,
      {LoggerJSON.Formatters.Basic, formatter_config}
    )
  end
end
