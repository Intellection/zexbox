defmodule Exbox.Sanitizers.String do
  def sanitize(value) when is_binary(value) do
    filter_keys = ~w(password key userpwd access_token new_password)
    mask = "[FILTERED]"

    sanitized_value =
      Enum.reduce(filter_keys, value, fn filter_key, acc ->
        regex_pattern = ~r/(\\?|&|^)#{Regex.escape(filter_key)}=\w*/
        String.replace(acc, regex_pattern, "\\1#{filter_key}=#{mask}")
      end)

    sanitized_value
  end

  # Add this clause to handle nil values
  def sanitize(nil), do: nil

  def sanitize(value), do: value
end
