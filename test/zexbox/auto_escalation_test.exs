defmodule Zexbox.AutoEscalationTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  import Mock
  alias Zexbox.AutoEscalation

  @existing_ticket %{
    "key" => "SS-42",
    "id" => "10042",
    "self" => "https://zigroup.atlassian.net/rest/api/3/issue/10042",
    "url" => "https://zigroup.atlassian.net/browse/SS-42"
  }

  @created_ticket %{
    "key" => "SS-1",
    "id" => "10001",
    "self" => "https://zigroup.atlassian.net/rest/api/3/issue/10001",
    "url" => "https://zigroup.atlassian.net/browse/SS-1"
  }

  defp jira_mocks(overrides \\ []) do
    Keyword.merge(
      [
        search_latest_issues: fn _jql, _project_key -> {:ok, []} end,
        create_issue: fn _project_key, _summary, _desc, _type, _priority, _fields ->
          {:ok, @created_ticket}
        end,
        transition_issue: fn _issue_key, _status_name ->
          {:ok, %{success: true, status: "To do"}}
        end,
        add_comment: fn _issue_key, _comment -> {:ok, %{"id" => "comment-1"}} end,
        bug_fingerprint_field: fn ->
          %{id: "customfield_13442", name: "Bug Fingerprint[Short text]"}
        end,
        zigl_team_field: fn -> %{id: "customfield_10101", name: "ZIGL Team[Dropdown]"} end
      ],
      overrides
    )
  end

  defp otel_mocks(overrides \\ []) do
    Keyword.merge(
      [
        generate_trace_url: fn -> nil end,
        kibana_log_url: fn -> nil end
      ],
      overrides
    )
  end

  defp all_mocks(jira_overrides \\ [], otel_overrides \\ []) do
    [
      {Zexbox.JiraClient, [], jira_mocks(jira_overrides)},
      {Zexbox.OpenTelemetry, [], otel_mocks(otel_overrides)}
    ]
  end

  defp error, do: %RuntimeError{message: "Something broke"}

  # Capturing mock helper — returns the args that were passed to create_issue.
  defp capture_create_issue do
    me = self()

    [
      create_issue: fn project_key, summary, description, issuetype, priority, custom_fields ->
        send(
          me,
          {:create_opts,
           %{
             project_key: project_key,
             summary: summary,
             description: description,
             issuetype: issuetype,
             priority: priority,
             custom_fields: custom_fields
           }}
        )

        {:ok, @created_ticket}
      end
    ]
  end

  defp capture_add_comment do
    me = self()

    [
      add_comment: fn issue_key, comment ->
        send(me, {:comment_opts, {issue_key, comment}})
        {:ok, %{}}
      end
    ]
  end

  defp capture_search do
    me = self()

    [
      search_latest_issues: fn jql, _project_key ->
        send(me, {:search_jql, jql})
        {:ok, []}
      end
    ]
  end

  setup do
    Application.put_env(:zexbox, :auto_escalation_enabled, true)
    Application.put_env(:zexbox, :app_env, :sandbox)

    on_exit(fn ->
      Application.delete_env(:zexbox, :auto_escalation_enabled)
      Application.delete_env(:zexbox, :app_env)
    end)

    :ok
  end

  describe "generate_fingerprint/2" do
    test "returns action::ErrorClass format" do
      assert "checkout::StandardError" =
               AutoEscalation.generate_fingerprint("StandardError", "checkout")
    end
  end

  describe "handle_error/9 — when disabled" do
    test "returns {:disabled, nil} without calling Jira" do
      Application.put_env(:zexbox, :auto_escalation_enabled, false)

      with_mocks(all_mocks()) do
        result = AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

        assert result == {:disabled, nil}
        refute called(Zexbox.JiraClient.search_latest_issues(:_, :_))
        refute called(Zexbox.JiraClient.create_issue(:_, :_, :_, :_, :_, :_))
      end
    end
  end

  describe "handle_error/9 — new ticket path" do
    test "returns {:ok, ticket} and calls create_issue" do
      with_mocks(all_mocks()) do
        assert {:ok, ticket} =
                 AutoEscalation.handle_error(error(), "checkout", "High", "Purchase Ops")

        assert ticket["key"] == "SS-1"
        assert called(Zexbox.JiraClient.create_issue(:_, :_, :_, :_, :_, :_))
      end
    end

    test "creates issue with correct project key, summary, type, and priority" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Purchase Ops")

        assert_received {:create_opts, opts}
        assert opts.project_key == "SS"
        assert opts.summary == "checkout: RuntimeError"
        assert opts.issuetype == "Bug"
        assert opts.priority == "High"
      end
    end

    test "uses SP project key in production" do
      Application.put_env(:zexbox, :app_env, :production)

      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(error(), "pay", "High", "Payments")

        assert_received {:create_opts, opts}
        assert opts.project_key == "SP"
      end
    end

    test "always transitions the new ticket to 'To do'" do
      with_mocks(all_mocks()) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

        assert called(Zexbox.JiraClient.transition_issue(:_, :_))
      end
    end

    test "transitions to 'To do' using the ticket key returned by create_issue" do
      me = self()

      jira_overrides = [
        transition_issue: fn issue_key, status_name ->
          send(me, {:transition_opts, {issue_key, status_name}})
          {:ok, %{}}
        end
      ]

      with_mocks(all_mocks(jira_overrides)) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

        assert_received {:transition_opts, {issue_key, status_name}}
        assert issue_key == "SS-1"
        assert status_name == "To do"
      end
    end

    test "sets bug fingerprint custom field to the generated fingerprint" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Purchase Ops")

        assert_received {:create_opts, opts}
        assert opts.custom_fields["customfield_13442"] == "checkout::RuntimeError"
      end
    end

    test "sets zigl team custom field" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Purchase Ops")

        assert_received {:create_opts, opts}
        assert opts.custom_fields["customfield_10101"] == %{"value" => "Purchase Ops"}
      end
    end

    test "uses custom fingerprint override when provided" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error(),
          "checkout",
          "High",
          "Ops",
          nil,
          %{},
          %{},
          "custom::fingerprint"
        )

        assert_received {:create_opts, opts}
        assert opts.custom_fields["customfield_13442"] == "custom::fingerprint"
      end
    end

    test "description is a valid ADF doc map" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error(),
          "pay",
          "Medium",
          "Payments",
          nil,
          %{email: "u@example.com"},
          %{basket_id: 123}
        )

        assert_received {:create_opts, opts}
        assert opts.description.version == 1
        assert opts.description.type == "doc"
        assert is_list(opts.description.content)
      end
    end

    test "JQL search includes all resolved statuses to exclude closed tickets" do
      with_mocks(all_mocks(capture_search())) do
        AutoEscalation.handle_error(error(), "pay", "High", "Payments")

        assert_received {:search_jql, jql}
        assert jql =~ "Done"
        assert jql =~ "No Further Action"
        assert jql =~ "Ready for Support Approval"
      end
    end

    test "returns {:error, reason} and logs when create_issue fails" do
      jira_overrides = [
        create_issue: fn _project_key, _summary, _desc, _type, _priority, _fields ->
          {:error, "JIRA down"}
        end
      ]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:error, reason} =
                     AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

            assert reason =~ "Failed to create Jira ticket"
          end
        end)

      assert log =~ "Failed to create Jira ticket"
    end
  end

  describe "handle_error/9 — existing ticket path" do
    test "returns the existing ticket and adds a comment" do
      jira_overrides = [
        search_latest_issues: fn _jql, _project_key -> {:ok, [@existing_ticket]} end
      ]

      with_mocks(all_mocks(jira_overrides)) do
        assert {:ok, ticket} = AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

        assert ticket["key"] == "SS-42"
        refute called(Zexbox.JiraClient.create_issue(:_, :_, :_, :_, :_, :_))
        assert called(Zexbox.JiraClient.add_comment(:_, :_))
      end
    end

    test "comment targets the existing ticket key" do
      jira_overrides =
        [search_latest_issues: fn _jql, _project_key -> {:ok, [@existing_ticket]} end] ++
          capture_add_comment()

      with_mocks(all_mocks(jira_overrides)) do
        AutoEscalation.handle_error(error(), "checkout", "High", "Ops")
      end

      assert_received {:comment_opts, {issue_key, comment}}
      assert issue_key == "SS-42"
      assert comment.version == 1
      assert comment.type == "doc"
    end

    test "still returns {:ok, ticket} when add_comment fails" do
      jira_overrides = [
        search_latest_issues: fn _jql, _project_key -> {:ok, [@existing_ticket]} end,
        add_comment: fn _issue_key, _comment -> {:error, "Comment failed"} end
      ]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:ok, ticket} =
                     AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

            assert ticket["key"] == "SS-42"
          end
        end)

      assert log =~ "Failed to add comment"
    end
  end

  describe "handle_error/9 — search failure" do
    test "logs and falls through to create a new ticket when search fails" do
      jira_overrides = [
        search_latest_issues: fn _jql, _project_key -> {:error, "Search failed"} end
      ]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:ok, ticket} =
                     AutoEscalation.handle_error(error(), "checkout", "High", "Ops")

            assert ticket["key"] == "SS-1"
            assert called(Zexbox.JiraClient.create_issue(:_, :_, :_, :_, :_, :_))
          end
        end)

      assert log =~ "Failed to find existing Jira ticket"
    end
  end
end
