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
        search_latest_issues: fn _opts -> {:ok, []} end,
        create_issue: fn _opts -> {:ok, @created_ticket} end,
        transition_issue: fn _opts -> {:ok, %{success: true, status: "To do"}} end,
        add_comment: fn _opts -> {:ok, %{"id" => "comment-1"}} end,
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
        datadog_session_url: fn -> nil end,
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

  # Capturing mock helper — returns the opts that were passed to create_issue.
  defp capture_create_issue do
    me = self()
    [create_issue: fn opts -> send(me, {:create_opts, opts}); {:ok, @created_ticket} end]
  end

  defp capture_add_comment do
    me = self()
    [add_comment: fn opts -> send(me, {:comment_opts, opts}); {:ok, %{}} end]
  end

  defp capture_search do
    me = self()
    [search_latest_issues: fn opts -> send(me, {:search_opts, opts}); {:ok, []} end]
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

  describe "generate_fingerprint/1" do
    test "returns action::ErrorClass format" do
      assert "checkout::StandardError" =
               AutoEscalation.generate_fingerprint(
                 error_class: "StandardError",
                 action: "checkout"
               )
    end
  end

  describe "handle_error/1 — when disabled" do
    test "returns {:disabled, nil} without calling Jira" do
      Application.put_env(:zexbox, :auto_escalation_enabled, false)

      with_mocks(all_mocks()) do
        result =
          AutoEscalation.handle_error(
            error: error(),
            action: "checkout",
            priority: "High",
            zigl_team: "Ops"
          )

        assert result == {:disabled, nil}
        refute called(Zexbox.JiraClient.search_latest_issues(:_))
        refute called(Zexbox.JiraClient.create_issue(:_))
      end
    end
  end

  describe "handle_error/1 — new ticket path" do
    test "returns {:ok, ticket} and calls create_issue" do
      with_mocks(all_mocks()) do
        assert {:ok, ticket} =
                 AutoEscalation.handle_error(
                   error: error(),
                   action: "checkout",
                   priority: "High",
                   zigl_team: "Purchase Ops"
                 )

        assert ticket["key"] == "SS-1"
        assert called(Zexbox.JiraClient.create_issue(:_))
      end
    end

    test "creates issue with correct project key, summary, type, and priority" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Purchase Ops"
        )

        assert_received {:create_opts, opts}
        assert Keyword.get(opts, :project_key) == "SS"
        assert Keyword.get(opts, :summary) == "checkout: RuntimeError"
        assert Keyword.get(opts, :issuetype) == "Bug"
        assert Keyword.get(opts, :priority) == "High"
      end
    end

    test "uses SP project key in production" do
      Application.put_env(:zexbox, :app_env, :production)

      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "pay",
          priority: "High",
          zigl_team: "Payments"
        )

        assert_received {:create_opts, opts}
        assert Keyword.get(opts, :project_key) == "SP"
      end
    end

    test "always transitions the new ticket to 'To do'" do
      with_mocks(all_mocks()) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Ops"
        )

        assert called(Zexbox.JiraClient.transition_issue(:_))
      end
    end

    test "transitions to 'To do' using the ticket key returned by create_issue" do
      me = self()

      jira_overrides = [
        transition_issue: fn opts -> send(me, {:transition_opts, opts}); {:ok, %{}} end
      ]

      with_mocks(all_mocks(jira_overrides)) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Ops"
        )

        assert_received {:transition_opts, opts}
        assert Keyword.get(opts, :issue_key) == "SS-1"
        assert Keyword.get(opts, :status_name) == "To do"
      end
    end

    test "sets bug fingerprint custom field to the generated fingerprint" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Purchase Ops"
        )

        assert_received {:create_opts, opts}
        custom_fields = Keyword.get(opts, :custom_fields)
        assert custom_fields["customfield_13442"] == "checkout::RuntimeError"
      end
    end

    test "sets zigl team custom field" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Purchase Ops"
        )

        assert_received {:create_opts, opts}
        custom_fields = Keyword.get(opts, :custom_fields)
        assert custom_fields["customfield_10101"] == %{"value" => "Purchase Ops"}
      end
    end

    test "uses custom fingerprint override when provided" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Ops",
          fingerprint: "custom::fingerprint"
        )

        assert_received {:create_opts, opts}
        custom_fields = Keyword.get(opts, :custom_fields)
        assert custom_fields["customfield_13442"] == "custom::fingerprint"
      end
    end

    test "description is a valid ADF doc map" do
      with_mocks(all_mocks(capture_create_issue())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "pay",
          priority: "Medium",
          zigl_team: "Payments",
          user_context: %{email: "u@example.com"},
          additional_context: %{basket_id: 123}
        )

        assert_received {:create_opts, opts}
        description = Keyword.get(opts, :description)
        assert description.version == 1
        assert description.type == "doc"
        assert is_list(description.content)
      end
    end

    test "JQL search includes all resolved statuses to exclude closed tickets" do
      with_mocks(all_mocks(capture_search())) do
        AutoEscalation.handle_error(
          error: error(),
          action: "pay",
          priority: "High",
          zigl_team: "Payments"
        )

        assert_received {:search_opts, opts}
        jql = Keyword.get(opts, :jql, "")
        assert jql =~ "Done"
        assert jql =~ "No Further Action"
        assert jql =~ "Ready for Support Approval"
      end
    end

    test "returns {:error, reason} and logs when create_issue fails" do
      jira_overrides = [create_issue: fn _opts -> {:error, "JIRA down"} end]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:error, reason} =
                     AutoEscalation.handle_error(
                       error: error(),
                       action: "checkout",
                       priority: "High",
                       zigl_team: "Ops"
                     )

            assert reason =~ "Failed to create Jira ticket"
          end
        end)

      assert log =~ "Failed to create Jira ticket"
    end
  end

  describe "handle_error/1 — existing ticket path" do
    test "returns the existing ticket and adds a comment" do
      jira_overrides = [search_latest_issues: fn _opts -> {:ok, [@existing_ticket]} end]

      with_mocks(all_mocks(jira_overrides)) do
        assert {:ok, ticket} =
                 AutoEscalation.handle_error(
                   error: error(),
                   action: "checkout",
                   priority: "High",
                   zigl_team: "Ops"
                 )

        assert ticket["key"] == "SS-42"
        refute called(Zexbox.JiraClient.create_issue(:_))
        assert called(Zexbox.JiraClient.add_comment(:_))
      end
    end

    test "comment targets the existing ticket key" do
      jira_overrides =
        [search_latest_issues: fn _opts -> {:ok, [@existing_ticket]} end] ++
          capture_add_comment()

      with_mocks(all_mocks(jira_overrides)) do
        AutoEscalation.handle_error(
          error: error(),
          action: "checkout",
          priority: "High",
          zigl_team: "Ops"
        )
      end

      assert_received {:comment_opts, opts}
      assert Keyword.get(opts, :issue_key) == "SS-42"
      comment = Keyword.get(opts, :comment)
      assert comment.version == 1
      assert comment.type == "doc"
    end

    test "still returns {:ok, ticket} when add_comment fails" do
      jira_overrides = [
        search_latest_issues: fn _opts -> {:ok, [@existing_ticket]} end,
        add_comment: fn _opts -> {:error, "Comment failed"} end
      ]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:ok, ticket} =
                     AutoEscalation.handle_error(
                       error: error(),
                       action: "checkout",
                       priority: "High",
                       zigl_team: "Ops"
                     )

            assert ticket["key"] == "SS-42"
          end
        end)

      assert log =~ "Failed to add comment"
    end
  end

  describe "handle_error/1 — search failure" do
    test "logs and falls through to create a new ticket when search fails" do
      jira_overrides = [search_latest_issues: fn _opts -> {:error, "Search failed"} end]

      log =
        capture_log(fn ->
          with_mocks(all_mocks(jira_overrides)) do
            assert {:ok, ticket} =
                     AutoEscalation.handle_error(
                       error: error(),
                       action: "checkout",
                       priority: "High",
                       zigl_team: "Ops"
                     )

            assert ticket["key"] == "SS-1"
            assert called(Zexbox.JiraClient.create_issue(:_))
          end
        end)

      assert log =~ "Failed to find existing Jira ticket"
    end
  end
end
