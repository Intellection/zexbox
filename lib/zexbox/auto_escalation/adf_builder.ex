defmodule Zexbox.AutoEscalation.AdfBuilder do
  @moduledoc """
  Builds Atlassian Document Format (ADF) maps for Jira issue descriptions and comments.

  Mirrors `Opsbox::AutoEscalation::AdfBuilder`. Produces the same ADF structure so
  headings, links, bullet lists, and the stack-trace expand render correctly in Jira.

  Unlike the Ruby version, `stacktrace` must be passed explicitly (as `__STACKTRACE__`
  from a `rescue` block) because Elixir exceptions do not carry their own backtrace.
  """

  alias Zexbox.OpenTelemetry

  @doc """
  Builds an ADF description map for a new Jira issue.

  Structure:
  1. Telemetry links (Tempo | Kibana)
  2. Divider (if `custom_description` present)
  3. Custom description paragraphs (split on `\\n\\n`)
  4. User context bullet list (if non-empty)
  5. Additional context bullet list (if non-empty)
  6. H3 "Error Details"
  7. Exception summary + expandable stack trace
  """
  @spec build_description(
          Exception.t(),
          map(),
          map(),
          Exception.stacktrace() | nil,
          String.t() | nil
        ) :: map()
  def build_description(
        exception,
        user_context,
        additional_context,
        stacktrace \\ nil,
        custom_description \\ nil
      ) do
    []
    |> build_body(exception, user_context, additional_context, stacktrace, custom_description)
    |> doc()
  end

  @doc """
  Builds an ADF comment map for an additional occurrence on an existing Jira issue.

  Structure:
  1. H2 "Additional Occurrence (action)"
  2. Telemetry links
  3. Divider + custom description (if present)
  4. Context bullet lists (if non-empty)
  5. H3 "Error Details"
  6. Exception summary + expandable stack trace
  """
  @spec build_comment(
          Exception.t(),
          String.t(),
          map(),
          map(),
          Exception.stacktrace() | nil,
          String.t() | nil
        ) :: map()
  def build_comment(
        exception,
        action,
        user_context,
        additional_context,
        stacktrace \\ nil,
        custom_description \\ nil
      ) do
    [heading(2, "Additional Occurrence (#{action})")]
    |> build_body(exception, user_context, additional_context, stacktrace, custom_description)
    |> doc()
  end

  # --- Private ---

  defp build_body(
         acc,
         exception,
         user_context,
         additional_context,
         stacktrace,
         custom_description
       ) do
    acc
    |> append_telemetry()
    |> append_description(custom_description)
    |> append_context(user_context, additional_context)
    |> append_error_details(exception, stacktrace)
  end

  defp append_telemetry(acc) do
    trace_url = OpenTelemetry.generate_trace_url()
    kibana_url = OpenTelemetry.kibana_log_url()

    inline =
      link_or_plain("Tempo Trace View", trace_url) ++
        [text(" | ")] ++
        link_or_plain("Kibana Logs", kibana_url)

    acc ++ [%{type: "paragraph", content: inline}]
  end

  defp append_description(acc, nil), do: acc
  defp append_description(acc, ""), do: acc

  defp append_description(acc, desc) do
    case String.trim(desc) do
      "" -> acc
      trimmed -> acc ++ [divider() | custom_description_blocks(trimmed)]
    end
  end

  defp append_context(acc, user_context, additional_context) do
    acc
    |> append_single_context("User Context", user_context)
    |> append_single_context("Additional Context", additional_context)
  end

  defp append_single_context(acc, _label, ctx) when not is_map(ctx), do: acc
  defp append_single_context(acc, _label, ctx) when map_size(ctx) == 0, do: acc

  defp append_single_context(acc, label, ctx) do
    acc ++ [%{type: "paragraph", content: [bold(label)]}, key_value_bullet_list(ctx)]
  end

  defp append_error_details(acc, exception, stacktrace) do
    error_class = inspect(exception.__struct__)
    message = Exception.message(exception)
    summary = "#{error_class}: #{message}"

    backtrace =
      case stacktrace do
        nil -> "No stack trace available"
        [] -> "No stack trace available"
        st -> Exception.format_stacktrace(st)
      end

    acc ++
      [
        heading(3, "Error Details"),
        %{type: "paragraph", content: [text(summary)]},
        expand("Stack trace", [code_block(backtrace)])
      ]
  end

  defp custom_description_blocks(desc) do
    desc
    |> String.split(~r/\n\n+/)
    |> Enum.map(fn paragraph ->
      %{type: "paragraph", content: [text(String.trim(paragraph))]}
    end)
  end

  defp key_value_bullet_list(hash) do
    items =
      Enum.map(hash, fn {key, value} ->
        %{
          type: "listItem",
          content: [
            %{
              type: "paragraph",
              content: [bold(key), text(": "), text(to_string(value))]
            }
          ]
        }
      end)

    %{type: "bulletList", content: items}
  end

  defp doc(content), do: %{version: 1, type: "doc", content: content}
  defp text(str), do: %{type: "text", text: str}
  defp bold(str), do: %{type: "text", text: to_string(str), marks: [%{type: "strong"}]}
  defp divider, do: %{type: "rule"}

  defp heading(level, text_content),
    do: %{type: "heading", attrs: %{level: level}, content: [text(text_content)]}

  defp code_block(content),
    do: %{type: "codeBlock", content: [%{type: "text", text: to_string(content)}]}

  defp expand(title, content_blocks),
    do: %{type: "expand", attrs: %{title: title}, content: content_blocks}

  defp link_or_plain(label, url) when is_binary(url) and url != "" do
    [%{type: "text", text: label, marks: [%{type: "link", attrs: %{href: url}}]}]
  end

  defp link_or_plain(label, _url) do
    [%{type: "text", text: "#{label} (Missing)"}]
  end
end
