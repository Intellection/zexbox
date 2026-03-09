defmodule Zexbox.AutoEscalation.AdfBuilderTest do
  use ExUnit.Case
  import Mock
  alias Zexbox.AutoEscalation.AdfBuilder

  defp with_telemetry_urls(trace, kibana, fun) do
    with_mocks([
      {Zexbox.OpenTelemetry, [],
       [
         generate_trace_url: fn -> trace end,
         kibana_log_url: fn -> kibana end
       ]}
    ]) do
      fun.()
    end
  end

  defp with_all_urls(fun),
    do:
      with_telemetry_urls(
        "https://grafana.example.com/trace",
        "https://kibana.example.com/logs",
        fun
      )

  defp with_no_urls(fun), do: with_telemetry_urls(nil, nil, fun)

  defp runtime_error(msg \\ "Something broke"), do: %RuntimeError{message: msg}

  describe "build_description/5" do
    test "returns an ADF doc map with correct version and type" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        assert result.version == 1
        assert result.type == "doc"
        assert is_list(result.content)
      end)
    end

    test "first block is a telemetry paragraph with Tempo and Kibana links" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        [telemetry | _rest] = result.content
        assert telemetry.type == "paragraph"
        json = Jason.encode!(telemetry)
        assert json =~ "Tempo Trace View"
        assert json =~ "https://grafana.example.com/trace"
        assert json =~ "Kibana Logs"
        assert json =~ "https://kibana.example.com/logs"
      end)
    end

    test "shows '(Missing)' for unavailable telemetry URLs" do
      with_no_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        [telemetry | _rest] = result.content
        json = Jason.encode!(telemetry)
        assert json =~ "Tempo Trace View (Missing)"
        assert json =~ "Kibana Logs (Missing)"
      end)
    end

    test "includes Error Details heading, exception class, message, and stack trace expand" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error("boom"), %{}, %{})
        json = Jason.encode!(result)
        assert json =~ "Error Details"
        assert json =~ "RuntimeError"
        assert json =~ "boom"
        assert json =~ "Stack trace"
        assert json =~ "No stack trace available"
      end)
    end

    test "formats provided stacktrace in the expand block" do
      with_all_urls(fn ->
        stacktrace = [{MyModule, :my_fn, 2, [file: ~c"lib/my_module.ex", line: 42]}]
        result = AdfBuilder.build_description(runtime_error(), %{}, %{}, stacktrace: stacktrace)
        json = Jason.encode!(result)
        assert json =~ "Stack trace"
        assert json =~ "my_module.ex"
      end)
    end

    test "includes custom_description paragraphs above Error Details" do
      with_all_urls(fn ->
        result =
          AdfBuilder.build_description(runtime_error(), %{}, %{},
            custom_description: "This happened during sync."
          )

        json = Jason.encode!(result)
        assert json =~ "This happened during sync."
        assert json =~ "Error Details"

        {cd_pos, _len} = :binary.match(json, "This happened during sync.")
        {ed_pos, _len} = :binary.match(json, "Error Details")
        assert cd_pos < ed_pos
      end)
    end

    test "splits custom_description on double newlines into multiple paragraphs" do
      with_all_urls(fn ->
        result =
          AdfBuilder.build_description(runtime_error(), %{}, %{},
            custom_description: "First.\n\nSecond."
          )

        json = Jason.encode!(result)
        assert json =~ "First."
        assert json =~ "Second."
      end)
    end

    test "adds a divider before custom_description when present" do
      with_all_urls(fn ->
        result =
          AdfBuilder.build_description(runtime_error(), %{}, %{},
            custom_description: "Some context."
          )

        json = Jason.encode!(result)
        assert json =~ ~s("type":"rule")
      end)
    end

    test "does not add a divider when custom_description is nil" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        json = Jason.encode!(result)
        refute json =~ ~s("type":"rule")
      end)
    end

    test "includes user_context as a bold key-value bullet list" do
      with_all_urls(fn ->
        result =
          AdfBuilder.build_description(runtime_error(), %{email: "u@example.com"}, %{})

        json = Jason.encode!(result)
        assert json =~ "User Context"
        assert json =~ "email"
        assert json =~ "u@example.com"
      end)
    end

    test "includes additional_context as a bold key-value bullet list" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{basket_id: 42})
        json = Jason.encode!(result)
        assert json =~ "Additional Context"
        assert json =~ "basket_id"
        assert json =~ "42"
      end)
    end

    test "omits User Context section when empty" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        json = Jason.encode!(result)
        refute json =~ "User Context"
      end)
    end

    test "omits Additional Context section when empty" do
      with_all_urls(fn ->
        result = AdfBuilder.build_description(runtime_error(), %{}, %{})
        json = Jason.encode!(result)
        refute json =~ "Additional Context"
      end)
    end
  end

  describe "build_comment/6" do
    test "starts with an Additional Occurrence heading including action name" do
      with_all_urls(fn ->
        result = AdfBuilder.build_comment(runtime_error(), "checkout", %{}, %{})
        json = Jason.encode!(result)
        assert json =~ "Additional Occurrence (checkout)"
      end)
    end

    test "includes telemetry paragraph" do
      with_all_urls(fn ->
        result = AdfBuilder.build_comment(runtime_error(), "pay", %{}, %{})
        json = Jason.encode!(result)
        assert json =~ "Tempo Trace View"
      end)
    end

    test "includes exception details and stack trace" do
      with_all_urls(fn ->
        result = AdfBuilder.build_comment(runtime_error("boom"), "pay", %{}, %{})
        json = Jason.encode!(result)
        assert json =~ "RuntimeError"
        assert json =~ "boom"
        assert json =~ "Stack trace"
      end)
    end

    test "includes context bullet lists when provided" do
      with_all_urls(fn ->
        result =
          AdfBuilder.build_comment(
            runtime_error(),
            "checkout",
            %{email: "u@example.com"},
            %{basket_id: 123}
          )

        json = Jason.encode!(result)
        assert json =~ "User Context"
        assert json =~ "u@example.com"
        assert json =~ "Additional Context"
        assert json =~ "123"
      end)
    end
  end
end
