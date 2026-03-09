defmodule Zexbox.JiraClient do
  @moduledoc """
  HTTP client for the Jira Cloud REST API v3.

  Mirrors `Opsbox::JiraClient`. Authenticates with Basic auth using
  `JIRA_USER_EMAIL_ADDRESS` and `JIRA_API_TOKEN` environment variables
  (or `:jira_email` / `:jira_api_token` application config).

  ## Configuration

  ```elixir
  config :zexbox,
    jira_base_url: "https://your-org.atlassian.net",
    jira_email: System.get_env("JIRA_USER_EMAIL_ADDRESS"),
    jira_api_token: System.get_env("JIRA_API_TOKEN")
  ```

  All public functions return `{:ok, result}` or `{:error, reason}`.
  """

  @bug_fingerprint_field %{id: "customfield_13442", name: "Bug Fingerprint[Short text]"}
  @zigl_team_field %{id: "customfield_10101", name: "ZIGL Team[Dropdown]"}

  @doc "Returns the bug fingerprint custom field metadata."
  @spec bug_fingerprint_field() :: %{id: String.t(), name: String.t()}
  def bug_fingerprint_field, do: @bug_fingerprint_field

  @doc "Returns the ZIGL team custom field metadata."
  @spec zigl_team_field() :: %{id: String.t(), name: String.t()}
  def zigl_team_field, do: @zigl_team_field

  @doc """
  Search for the latest issues matching a JQL query (max 50 results).

  - `jql` – JQL query string.
  - `project_key` – optional; prepends `project = KEY AND` to the JQL.

  Returns `{:ok, [issue_map]}` where each map includes a `"url"` browse key,
  or `{:error, reason}` on failure.
  """
  @spec search_latest_issues(String.t(), String.t() | nil) :: {:ok, [map()]} | {:error, term()}
  def search_latest_issues(jql, project_key \\ nil) do
    query = if project_key, do: "project = #{project_key} AND #{jql}", else: jql

    client = build_client()

    case jira_get(client, "/rest/api/3/issue/search",
           jql: query,
           maxResults: 50,
           fields: ["key", "id", "self", "status", "summary"]
         ) do
      {:ok, body} ->
        base_url = config(:jira_base_url, nil)
        issues = Map.get(body, "issues", [])
        issues = Enum.map(issues, &Map.put(&1, "url", "#{base_url}/browse/#{&1["key"]}"))
        {:ok, issues}

      {:error, _reason} = err ->
        err
    end
  end

  @doc """
  Create a new Jira issue.

  - `project_key` – Jira project key (e.g. `"SS"`).
  - `summary` – issue summary string.
  - `description` – ADF map (already built; not converted).
  - `issuetype` – issue type name (e.g. `"Bug"`).
  - `priority` – priority name (e.g. `"High"`).
  - `custom_fields` – optional map of custom field ID → value (string keys).

  Returns `{:ok, issue_map}` with a `"url"` browse key added, or `{:error, reason}`.
  """
  @spec create_issue(String.t(), String.t(), map(), String.t(), String.t(), map()) ::
          {:ok, map()} | {:error, term()}
  def create_issue(project_key, summary, description, issuetype, priority, custom_fields \\ %{}) do
    fields =
      Map.merge(
        %{
          "project" => %{"key" => project_key},
          "summary" => summary,
          "description" => description,
          "issuetype" => %{"name" => issuetype},
          "priority" => %{"name" => priority}
        },
        custom_fields
      )

    client = build_client()

    case jira_post(client, "/rest/api/3/issue", %{"fields" => fields}) do
      {:ok, result} ->
        base_url = config(:jira_base_url, nil)
        {:ok, Map.put(result, "url", "#{base_url}/browse/#{result["key"]}")}

      {:error, _reason} = err ->
        err
    end
  end

  @doc """
  Transition a Jira issue to a new status by name (case-insensitive match).

  - `issue_key` – issue key (e.g. `"SS-42"`).
  - `status_name` – target status name (e.g. `"To do"`).

  Returns `{:ok, %{success: true, status: name}}` or `{:error, reason}`.
  """
  @spec transition_issue(String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def transition_issue(issue_key, status_name) do
    client = build_client()

    with {:ok, data} <- jira_get(client, "/rest/api/3/issue/#{issue_key}/transitions"),
         transitions = Map.get(data, "transitions", []),
         {:ok, target} <- find_transition(transitions, status_name),
         {:ok, _resp} <-
           jira_post(client, "/rest/api/3/issue/#{issue_key}/transitions", %{
             "transition" => %{"id" => target["id"]}
           }) do
      {:ok, %{success: true, status: get_in(target, ["to", "name"])}}
    end
  end

  @doc """
  Add a comment to an existing Jira issue.

  - `issue_key` – issue key (e.g. `"SS-42"`).
  - `comment` – ADF map for the comment body (already built; not converted).

  Returns `{:ok, comment_map}` or `{:error, reason}`.
  """
  @spec add_comment(String.t(), map()) :: {:ok, map()} | {:error, term()}
  def add_comment(issue_key, comment) do
    client = build_client()
    jira_post(client, "/rest/api/3/issue/#{issue_key}/comment", %{"body" => comment})
  end

  defp find_transition(transitions, status_name) do
    case Enum.find(transitions, fn t ->
           to_name = get_in(t, ["to", "name"]) || ""
           String.downcase(to_name) == String.downcase(status_name)
         end) do
      nil -> {:error, "Cannot transition to '#{status_name}'"}
      target -> {:ok, target}
    end
  end

  defp jira_get(client, path, params \\ []) do
    case Req.get(client, url: path, params: params) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body || %{}}

      {:ok, %{status: status, body: body}} ->
        {:error, "HTTP #{status}: #{inspect(body)}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp jira_post(client, path, body) do
    case Req.post(client, url: path, json: body) do
      {:ok, %{status: status, body: resp_body}} when status in 200..299 ->
        {:ok, resp_body || %{}}

      {:ok, %{status: status, body: resp_body}} ->
        {:error, "HTTP #{status}: #{inspect(resp_body)}"}

      {:error, reason} ->
        {:error, inspect(reason)}
    end
  end

  defp build_client do
    base_url = config(:jira_base_url, nil)
    email = config(:jira_email, System.get_env("JIRA_USER_EMAIL_ADDRESS", ""))
    token = config(:jira_api_token, System.get_env("JIRA_API_TOKEN", ""))

    Req.new(
      base_url: base_url,
      auth: {:basic, "#{email}:#{token}"},
      headers: [{"accept", "application/json"}]
    )
  end

  defp config(key, default), do: Application.get_env(:zexbox, key, default)
end
