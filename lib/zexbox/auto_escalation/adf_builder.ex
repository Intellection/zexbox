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
  1. Telemetry links (Datadog | Tempo | Kibana)
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
          keyword()
        ) :: map()
  def build_description(exception, user_context, additional_context, opts \\ []) do
    custom_description = Keyword.get(opts, :custom_description)
    stacktrace = Keyword.get(opts, :stacktrace)

    content =
      [telemetry_paragraph()]
      |> add_if(has_content?(custom_description), divider())
      |> Kernel.++(custom_description_blocks(custom_description))
      |> Kernel.++(context_blocks(user_context, additional_context))
      |> Kernel.++([heading(3, "Error Details")])
      |> Kernel.++(error_details_blocks(exception, stacktrace))

    doc(content)
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
          keyword()
        ) :: map()
  def build_comment(exception, action, user_context, additional_context, opts \\ []) do
    custom_description = Keyword.get(opts, :custom_description)
    stacktrace = Keyword.get(opts, :stacktrace)

    content =
      [heading(2, "Additional Occurrence (#{action})"), telemetry_paragraph()]
      |> add_if(has_content?(custom_description), divider())
      |> Kernel.++(custom_description_blocks(custom_description))
      |> Kernel.++(context_blocks(user_context, additional_context))
      |> Kernel.++([heading(3, "Error Details")])
      |> Kernel.++(error_details_blocks(exception, stacktrace))

    doc(content)
  end

  # --- Private ---

  defp doc(content), do: %{version: 1, type: "doc", content: content}

  defp telemetry_paragraph do
    trace_url = OpenTelemetry.generate_trace_url()
    kibana_url = OpenTelemetry.kibana_log_url()

    inline =
      link_or_plain("Tempo Trace View", trace_url) ++
        [text(" | ")] ++
        link_or_plain("Kibana Logs", kibana_url)

    %{type: "paragraph", content: inline}
  end

  defp link_or_plain(label, url) when is_binary(url) and url != "" do
    [%{type: "text", text: label, marks: [%{type: "link", attrs: %{href: url}}]}]
  end

  defp link_or_plain(label, _url) do
    [%{type: "text", text: "#{label} (Missing)"}]
  end

  defp text(str), do: %{type: "text", text: str}
  defp bold(str), do: %{type: "text", text: to_string(str), marks: [%{type: "strong"}]}
  defp divider, do: %{type: "rule"}

  defp heading(level, text_content),
    do: %{type: "heading", attrs: %{level: level}, content: [text(text_content)]}

  defp code_block(content),
    do: %{type: "codeBlock", content: [%{type: "text", text: to_string(content)}]}

  defp expand(title, content_blocks),
    do: %{type: "expand", attrs: %{title: title}, content: content_blocks}

  defp custom_description_blocks(nil), do: []
  defp custom_description_blocks(""), do: []

  defp custom_description_blocks(custom_description) do
    custom_description
    |> String.trim()
    |> String.split(~r/\n\n+/)
    |> Enum.map(fn paragraph ->
      %{type: "paragraph", content: [text(String.trim(paragraph))]}
    end)
  end

  defp error_details_blocks(exception, stacktrace) do
    error_class = inspect(exception.__struct__)
    message = Exception.message(exception)
    summary = "#{error_class}: #{message}"

    backtrace =
      case stacktrace do
        nil -> "No stack trace available"
        [] -> "No stack trace available"
        st -> Exception.format_stacktrace(st)
      end

    [
      %{type: "paragraph", content: [text(summary)]},
      expand("Stack trace", [code_block(backtrace)])
    ]
  end

  defp context_blocks(user_context, additional_context) do
    []
    |> maybe_add_context("User Context", user_context)
    |> maybe_add_context("Additional Context", additional_context)
  end

  defp maybe_add_context(blocks, _label, ctx) when is_map(ctx) and map_size(ctx) == 0, do: blocks
  defp maybe_add_context(blocks, _label, ctx) when not is_map(ctx), do: blocks

  defp maybe_add_context(blocks, label, ctx) do
    blocks ++
      [%{type: "paragraph", content: [bold(label)]}] ++
      [key_value_bullet_list(ctx)]
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

  defp add_if(list, true, item), do: list ++ [item]
  defp add_if(list, false, _item), do: list

  defp has_content?(nil), do: false
  defp has_content?(""), do: false
  defp has_content?(str) when is_binary(str), do: String.trim(str) != ""
  defp has_content?(_), do: false
end
