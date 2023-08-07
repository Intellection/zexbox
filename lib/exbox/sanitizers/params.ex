defmodule Exbox.Sanitizers.Params do
  alias Exbox.Sanitizers.String

  def sanitize(%{params: params} = input) when is_binary(params) do
    case Jason.decode!(params) do
      map -> sanitize_map(Map.put(input, :params, map))
      _ -> String.sanitize(value: params)
    end
  rescue
    _ -> String.sanitize(value: params)
  end

  def sanitize(%{params: params}) when is_map(params) do
    sanitize_map(params)
  end

  def sanitize(%{params: params}) when is_list(params) do
    sanitize_list(params)
  end

  def sanitize(params) when is_binary(params) do
    String.sanitize(value: params)
  end

  def sanitize(params), do: params

  defp sanitize_map(map) do
    Enum.reduce(map, %{}, fn {key, value}, output ->
      output_key =
        case value do
          %{} -> sanitize(value)
          _ -> value
        end

      output |> Map.put(key, output_key)
    end)
  end

  defp sanitize_list(list) do
    Enum.map(list, fn entry -> sanitize(entry) end)
  end
end
