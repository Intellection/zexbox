defmodule Zexbox.Logging.JsonFormatter do
  @moduledoc """
  Returns a `:logger` formatter tuple suitable for Logstash / Elasticsearch
  ingestion, wrapping `LoggerJSON.Formatters.Basic` with Zappi-standard
  defaults.

  Splat into `config/runtime.exs`:

      config :logger, :default_handler,
        formatter: Zexbox.Logging.JsonFormatter.config()

  Mirrors opsbox's Ruby-side `JsonFormatter`: every log event becomes one
  JSON object on one line, so multi-line content (struct inspections,
  multi-line SQL, stack traces) collapses into a single Elasticsearch
  document at the ingest layer.

  ## Why declarative

  `:logger` is configured before `Application.start/2` runs. Logs emitted
  during application boot use the formatter that has been *configured* —
  not one installed imperatively at runtime. Pure config makes JSON
  active from the first log line emitted by the BEAM.

  ## Encoder

  Consumers choose the JSON encoder. The default for `LoggerJSON` is
  Jason; on Elixir 1.18+ you can opt into the stdlib `JSON` module with:

      config :logger_json, encoder: JSON

  This is a compile-time setting in `config/config.exs`.
  """

  alias LoggerJSON.{Formatters.Basic, Redactors.RedactKeys}

  @default_metadata [
    :request_id,
    :trace_id,
    :span_id,
    :user_id,
    :pid,
    :module,
    :function,
    :line,
    :application
  ]

  @default_redactors [
    {RedactKeys, ["password", "secret", "token", "authorization", "api_key", "session"]}
  ]

  @doc """
  Returns the formatter tuple for `config :logger, :default_handler, formatter: ...`.

  ## Options

    * `:metadata` — list of `Logger` metadata keys to include in the JSON
      output, or `:all` to include every key set via `Logger.metadata/1`.
      Defaults to a curated Zappi list (see `default_metadata/0`). Pass
      an explicit list to override; metadata is a security-adjacent
      surface and `:all` is **not** recommended for production.

    * `:redactors` — list of `LoggerJSON.Redactor` tuples. Defaults to a
      single `RedactKeys` redactor stripping common credential keys
      (see `default_redactors/0`). Pass `[]` to disable redaction; pass
      a list to extend or override.

  ## Examples

      iex> {mod, _config} = Zexbox.Logging.JsonFormatter.config()
      iex> mod
      LoggerJSON.Formatters.Basic
  """
  @spec config(keyword()) :: {module(), map()}
  def config(opts \\ []) do
    Basic.new(
      metadata: Keyword.get(opts, :metadata, @default_metadata),
      redactors: Keyword.get(opts, :redactors, @default_redactors)
    )
  end

  @doc "The default metadata allow-list, exposed for inspection or extension."
  @spec default_metadata() :: list(atom())
  def default_metadata, do: @default_metadata

  @doc "The default redactor list, exposed for inspection or extension."
  @spec default_redactors() :: list({module(), term()})
  def default_redactors, do: @default_redactors
end
