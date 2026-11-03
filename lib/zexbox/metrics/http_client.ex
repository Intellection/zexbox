defmodule Zexbox.Metrics.HTTPClient do
  @moduledoc """
  `Instream.HTTPClient` that works with hackney 1.x and 4.x.

  Instream's built-in client reads the body with `:hackney.body/1`, which
  hackney 4 no longer supports: it returns the body in the response tuple.
  """

  @behaviour Instream.HTTPClient

  # The ref clause is for consumers still resolving hackney 1.x; dialyzer only sees 4.x.
  @dialyzer {:no_match, request: 5}

  @impl Instream.HTTPClient
  def request(:head, url, headers, body, opts),
    do: :hackney.request(:head, url, headers, body, opts)

  def request(method, url, headers, body, opts) do
    case :hackney.request(method, url, headers, body, opts) do
      {:ok, status, resp_headers, resp_body} when is_binary(resp_body) ->
        {:ok, status, resp_headers, resp_body}

      {:ok, status, resp_headers, client} ->
        with {:ok, resp_body} <- :hackney.body(client),
             do: {:ok, status, resp_headers, resp_body}

      {:error, _reason} = error ->
        error
    end
  end
end
