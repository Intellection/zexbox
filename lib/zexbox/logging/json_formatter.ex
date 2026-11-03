if Code.ensure_loaded?(LoggerJSON) do
  defmodule Zexbox.Logging.JsonFormatter do
    @moduledoc """
    Builds a `:logger` formatter that writes every log event as one line of JSON,
    using `LoggerJSON.Formatters.Basic` with Zappi defaults.

    Filebeat ships each line as its own Elasticsearch document, so plain-text
    output with struct inspections, multi-line SQL or stack traces fans out into
    many documents. One JSON line per event keeps it to one.

    Requires `{:logger_json, "~> 7.0"}` in the app's deps. Call it from
    `config/runtime.exs`:

        config :logger, :default_handler,
          formatter: Zexbox.Logging.JsonFormatter.config()

    It can't be called from `config/config.exs` or `config/prod.exs`: those are
    evaluated before dependencies are compiled.
    """

    alias LoggerJSON.Formatters.Basic
    alias LoggerJSON.Redactors.RedactKeys

    @default_metadata [
      :request_id,
      :user_id,
      :application,
      :mfa,
      :file,
      :line,
      :pid
    ]

    @redacted_keys ~w(
      password password_confirmation current_password
      secret client_secret secret_key_base
      token access_token refresh_token id_token api_token auth_token
      api_key x-api-key
      authorization Authorization
      cookie session
    )

    @default_redactors [{RedactKeys, @redacted_keys}]

    @doc """
    Returns the `{formatter_module, config}` tuple for `config :logger, :default_handler, formatter: ...`.

    Takes any option `LoggerJSON.Formatters.Basic.new/1` accepts. Options given
    replace the defaults for that key:

      * `:metadata` - defaults to `default_metadata/0`. Avoid `:all` in production.
        Trace and span IDs are always written as top-level `trace` and `span` fields.
      * `:redactors` - defaults to `default_redactors/0`. Pass `[]` to disable.
        Redactors match exact key names and only apply to metadata and map or
        keyword messages, never to string messages.
      * `:encoder_opts` - passed straight through.

    ## Examples

        iex> {module, _config} = Zexbox.Logging.JsonFormatter.config()
        iex> module
        LoggerJSON.Formatters.Basic
    """
    @spec config(keyword()) :: {module(), map()}
    def config(opts \\ []) do
      [metadata: @default_metadata, redactors: @default_redactors]
      |> Keyword.merge(opts)
      |> Basic.new()
    end

    @doc "The default metadata allow-list."
    @spec default_metadata() :: [atom()]
    def default_metadata, do: @default_metadata

    @doc "The default redactors."
    @spec default_redactors() :: [{module(), term()}]
    def default_redactors, do: @default_redactors
  end
end
