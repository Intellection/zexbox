defmodule Zexbox.AutoEscalation do
  @moduledoc """
  Automatic error-to-on-call escalation via Jira.

  Mirrors `Opsbox::AutoEscalation`. When an error occurs, this module finds an
  existing open Jira ticket by fingerprint or creates a new Bug, adds a comment on
  recurrence, and always transitions new tickets to "To do" to trigger the medic/IRM
  process.

  ## Usage

  Call from a `rescue` block and pass `__STACKTRACE__` so the stack trace is
  included in the ticket:

  ```elixir
  try do
    process_checkout(user, basket)
  rescue
    e ->
      Zexbox.AutoEscalation.handle_error(
        e,
        "checkout",
        "High",
        "Purchase Ops",
        stacktrace: __STACKTRACE__,
        user_context: %{email: user.email},
        additional_context: %{basket_id: basket.id}
      )
  end
  ```

  ## Return values

  - `{:ok, ticket_map}` – ticket found or created; map has `"key"`, `"id"`, `"self"`, `"url"`.
  - `{:error, reason}` – ticket creation or transition failed; rescue `Zexbox.AutoEscalation.Error`.
  - `{:disabled, nil}` – feature is disabled via config (no Jira calls made).

  ## Configuration

  ```elixir
  config :zexbox,
    jira_base_url: "https://zigroup.atlassian.net",
    jira_email: System.get_env("JIRA_USER_EMAIL_ADDRESS"),
    jira_api_token: System.get_env("JIRA_API_TOKEN"),
    auto_escalation_enabled: true,
    app_env: :production   # :production → SP project; anything else → SS project
  ```

  Disable per environment:

  ```elixir
  # config/dev.exs
  config :zexbox, auto_escalation_enabled: false
  ```
  """

  require Logger

  alias Zexbox.{JiraClient, AutoEscalation.AdfBuilder}

  defmodule Error do
    @moduledoc "Raised when Jira ticket creation or transition fails."
    defexception [:message]
  end

  @project_key_sandbox "SS"
  @project_key_support "SP"
  # Tickets in these statuses are considered resolved; new occurrences add a comment instead.
  @resolved_statuses ["Done", "No Further Action", "Ready for Support Approval"]
  @transition_to "To do"
  @issuetype "Bug"
  @compile_env Mix.env()

  @doc """
  Handle an error by finding or creating a Jira ticket.

  Required arguments:
  - `error` – the `Exception.t()` that was rescued.
  - `action` – short label (e.g. `"checkout"`); used in the fingerprint and summary.
  - `priority` – Jira priority name (e.g. `"High"`).
  - `zigl_team` – value for the ZIGL Team custom field.

  Optional options:
  - `:stacktrace` – pass `__STACKTRACE__` from the rescue block for a full trace.
  - `:user_context` – map rendered as a bullet list in the ticket body.
  - `:additional_context` – map of extra key/value pairs in the ticket body.
  - `:fingerprint` – override deduplication key; defaults to `"action::ErrorClass"`.
  - `:custom_description` – string rendered above Error Details (split on `\\n\\n`).
  """
  @spec handle_error(Exception.t(), String.t(), String.t(), String.t(), keyword()) ::
          {:ok, map()} | {:error, term()} | {:disabled, nil}
  def handle_error(error, action, priority, zigl_team, opts \\ []) do
    if auto_escalation_enabled?() do
      do_handle_error(error, action, priority, zigl_team, opts)
    else
      {:disabled, nil}
    end
  end

  @doc """
  Generates the default deduplication fingerprint for an error.

  ## Examples

      iex> Zexbox.AutoEscalation.generate_fingerprint("StandardError", "checkout")
      "checkout::StandardError"
  """
  @spec generate_fingerprint(String.t(), String.t()) :: String.t()
  def generate_fingerprint(error_class, action), do: "#{action}::#{error_class}"

  # --- Private ---

  defp do_handle_error(error, action, priority, zigl_team, opts) do
    unless is_exception(error) do
      raise ArgumentError, "Expected an Exception.t() for :error, got: #{inspect(error)}"
    end

    user_context = Keyword.get(opts, :user_context, %{})
    additional_context = Keyword.get(opts, :additional_context, %{})
    stacktrace = Keyword.get(opts, :stacktrace)
    custom_description = Keyword.get(opts, :custom_description)

    error_class = inspect(error.__struct__)

    fingerprint =
      Keyword.get(opts, :fingerprint) ||
        generate_fingerprint(error_class, action)

    case find_existing_ticket(fingerprint) do
      nil ->
        create_jira_ticket(
          error,
          action,
          priority,
          zigl_team,
          fingerprint,
          user_context,
          additional_context,
          custom_description,
          stacktrace
        )

      existing_ticket ->
        add_comment_to_existing_ticket(
          existing_ticket,
          error,
          action,
          user_context,
          additional_context,
          custom_description,
          stacktrace
        )

        {:ok, existing_ticket}
    end
  end

  defp find_existing_ticket(fingerprint) do
    project_key = resolve_project_key()
    escaped = String.replace(fingerprint, "\"", "\\\"")
    field_name = JiraClient.bug_fingerprint_field().name
    status_list = Enum.map_join(@resolved_statuses, ", ", fn s -> "\"#{s}\"" end)
    jql = "\"#{field_name}\" = \"#{escaped}\" AND status NOT IN (#{status_list})"

    case JiraClient.search_latest_issues(jql, project_key) do
      {:ok, []} ->
        nil

      {:ok, [first | _]} ->
        first

      {:error, e} ->
        Logger.error(
          "[Zexbox.AutoEscalation] Failed to find existing Jira ticket with fingerprint #{fingerprint}: #{inspect(e)}"
        )

        nil
    end
  end

  defp create_jira_ticket(
         error,
         action,
         priority,
         zigl_team,
         fingerprint,
         user_context,
         additional_context,
         custom_description,
         stacktrace
       ) do
    project_key = resolve_project_key()
    error_class = inspect(error.__struct__)

    description =
      AdfBuilder.build_description(
        error,
        user_context,
        additional_context,
        custom_description: custom_description,
        stacktrace: stacktrace
      )

    custom_fields = %{
      JiraClient.bug_fingerprint_field().id => fingerprint,
      JiraClient.zigl_team_field().id => %{"value" => zigl_team}
    }

    with {:ok, result} <-
           JiraClient.create_issue(
             project_key,
             "#{action}: #{error_class}",
             description,
             @issuetype,
             priority,
             custom_fields
           ),
         {:ok, _} <- JiraClient.transition_issue(result["key"], @transition_to) do
      {:ok, result}
    else
      {:error, e} ->
        Logger.error(
          "[Zexbox.AutoEscalation] Failed to create Jira ticket with fingerprint #{fingerprint} and action #{action}: #{inspect(e)}"
        )

        {:error, "Failed to create Jira ticket: #{inspect(e)}"}
    end
  end

  defp add_comment_to_existing_ticket(
         ticket,
         error,
         action,
         user_context,
         additional_context,
         custom_description,
         stacktrace
       ) do
    issue_key = ticket["key"]

    comment =
      AdfBuilder.build_comment(
        error,
        action,
        user_context,
        additional_context,
        custom_description: custom_description,
        stacktrace: stacktrace
      )

    case JiraClient.add_comment(issue_key, comment) do
      {:ok, _} ->
        :ok

      {:error, e} ->
        Logger.error(
          "[Zexbox.AutoEscalation] Failed to add comment to Jira ticket #{issue_key}: #{inspect(e)}"
        )

        :ok
    end
  end

  defp resolve_project_key do
    if app_env() == :production, do: @project_key_support, else: @project_key_sandbox
  end

  defp auto_escalation_enabled? do
    Application.get_env(:zexbox, :auto_escalation_enabled, true) == true
  end

  defp app_env, do: Application.get_env(:zexbox, :app_env, @compile_env)
end
