defmodule Zexbox.Metrics.HTTPClientTest do
  use ExUnit.Case, async: false

  import Mock

  alias Zexbox.Metrics.{Connection, HTTPClient}

  test "returns the body hackney 4 includes in the response" do
    with_mock :hackney,
      request: fn :post, _url, _headers, _body, _opts -> {:ok, 204, [{"a", "b"}], ""} end do
      assert HTTPClient.request(:post, "http://influx/write", [], "x", []) ==
               {:ok, 204, [{"a", "b"}], ""}
    end
  end

  test "reads the body from the client ref hackney 1 returns" do
    ref = make_ref()

    with_mock :hackney,
      request: fn :get, _url, _headers, _body, _opts -> {:ok, 200, [], ref} end,
      body: fn ^ref -> {:ok, "{}"} end do
      assert HTTPClient.request(:get, "http://influx/query", [], "", []) == {:ok, 200, [], "{}"}
    end
  end

  test "passes errors through" do
    with_mock :hackney,
      request: fn _method, _url, _headers, _body, _opts -> {:error, :econnrefused} end do
      assert HTTPClient.request(:post, "http://influx/write", [], "x", []) ==
               {:error, :econnrefused}
    end
  end

  test "passes HEAD responses through" do
    with_mock :hackney, request: fn :head, _url, _headers, _body, _opts -> {:ok, 204, []} end do
      assert HTTPClient.request(:head, "http://influx/ping", [], "", []) == {:ok, 204, []}
    end
  end

  test "is the connection's default client" do
    assert Connection.config(:http_client) == HTTPClient
  end
end
