defmodule Zexbox.JiraClientTest do
  use ExUnit.Case
  import Mock
  alias Zexbox.JiraClient

  @base_url "https://zigroup.atlassian.net"

  setup do
    Application.put_env(:zexbox, :jira_base_url, @base_url)
    Application.put_env(:zexbox, :jira_email, "test@example.com")
    Application.put_env(:zexbox, :jira_api_token, "test-token")

    on_exit(fn ->
      Application.delete_env(:zexbox, :jira_base_url)
      Application.delete_env(:zexbox, :jira_email)
      Application.delete_env(:zexbox, :jira_api_token)
    end)

    :ok
  end

  describe "bug_fingerprint_field/0" do
    test "returns the correct field metadata" do
      assert %{id: "customfield_13442", name: "Bug Fingerprint[Short text]"} =
               JiraClient.bug_fingerprint_field()
    end
  end

  describe "zigl_team_field/0" do
    test "returns the correct field metadata" do
      assert %{id: "customfield_10101", name: "ZIGL Team[Dropdown]"} =
               JiraClient.zigl_team_field()
    end
  end

  describe "search_latest_issues/2" do
    test_with_mock "returns issues with url keys added on success", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{
             "issues" => [
               %{
                 "key" => "SS-1",
                 "id" => "10001",
                 "self" => "#{@base_url}/rest/api/3/issue/10001"
               }
             ]
           }
         }}
      end do
      assert {:ok, [issue]} = JiraClient.search_latest_issues("status = Open", "SS")
      assert issue["key"] == "SS-1"
      assert issue["url"] == "#{@base_url}/browse/SS-1"
    end

    test_with_mock "returns empty list when no issues found", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:ok, %{status: 200, body: %{"issues" => []}}}
      end do
      assert {:ok, []} = JiraClient.search_latest_issues("status = Open")
    end

    test_with_mock "returns error on non-2xx response", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:ok, %{status: 401, body: %{"message" => "Unauthorized"}}}
      end do
      assert {:error, reason} = JiraClient.search_latest_issues("status = Open")
      assert reason =~ "HTTP 401"
    end

    test_with_mock "returns error on request failure", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:error, %{reason: :econnrefused}}
      end do
      assert {:error, _reason} = JiraClient.search_latest_issues("status = Open")
    end
  end

  describe "create_issue/6" do
    test_with_mock "creates issue and adds url to result", Req,
      new: fn _opts -> :mock_client end,
      post: fn :mock_client, _opts ->
        {:ok,
         %{
           status: 201,
           body: %{
             "key" => "SS-99",
             "id" => "10099",
             "self" => "#{@base_url}/rest/api/3/issue/10099"
           }
         }}
      end do
      assert {:ok, result} =
               JiraClient.create_issue(
                 "SS",
                 "checkout: RuntimeError",
                 %{version: 1, type: "doc", content: []},
                 "Bug",
                 "High",
                 %{"customfield_13442" => "checkout::RuntimeError"}
               )

      assert result["key"] == "SS-99"
      assert result["url"] == "#{@base_url}/browse/SS-99"
    end

    test_with_mock "returns error on non-2xx response", Req,
      new: fn _opts -> :mock_client end,
      post: fn :mock_client, _opts ->
        {:ok, %{status: 400, body: %{"errorMessages" => ["Invalid project"]}}}
      end do
      assert {:error, reason} =
               JiraClient.create_issue("INVALID", "test", %{}, "Bug", "High")

      assert reason =~ "HTTP 400"
    end
  end

  describe "transition_issue/2" do
    test_with_mock "transitions issue to target status", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{
             "transitions" => [
               %{"id" => "11", "to" => %{"name" => "To do"}},
               %{"id" => "21", "to" => %{"name" => "In Progress"}}
             ]
           }
         }}
      end,
      post: fn :mock_client, opts ->
        assert opts[:json] == %{"transition" => %{"id" => "11"}}
        {:ok, %{status: 204, body: nil}}
      end do
      assert {:ok, %{success: true, status: "To do"}} =
               JiraClient.transition_issue("SS-1", "To do")
    end

    test_with_mock "returns error when target status not found", Req,
      new: fn _opts -> :mock_client end,
      get: fn :mock_client, _opts ->
        {:ok,
         %{
           status: 200,
           body: %{"transitions" => [%{"id" => "11", "to" => %{"name" => "Done"}}]}
         }}
      end do
      assert {:error, reason} = JiraClient.transition_issue("SS-1", "Nonexistent")
      assert reason =~ "Cannot transition to"
    end
  end

  describe "add_comment/2" do
    test_with_mock "adds comment and returns the response", Req,
      new: fn _opts -> :mock_client end,
      post: fn :mock_client, _opts ->
        {:ok,
         %{
           status: 201,
           body: %{"id" => "30001", "body" => %{}, "author" => %{"displayName" => "Bot"}}
         }}
      end do
      comment = %{version: 1, type: "doc", content: []}
      assert {:ok, result} = JiraClient.add_comment("SS-42", comment)
      assert result["id"] == "30001"
    end

    test_with_mock "returns error on non-2xx response", Req,
      new: fn _opts -> :mock_client end,
      post: fn :mock_client, _opts ->
        {:ok, %{status: 404, body: %{"errorMessages" => ["Issue not found"]}}}
      end do
      assert {:error, reason} = JiraClient.add_comment("SS-999", %{})
      assert reason =~ "HTTP 404"
    end
  end
end
