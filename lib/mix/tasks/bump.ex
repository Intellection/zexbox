defmodule Mix.Tasks.Bump do
  @moduledoc """
  Bump version number in mix.exs and create a new git tag.
  """

  @spec run([binary]) :: :ok
  def run(args) do
    check_master_branch()
    {parsed, _, _} = OptionParser.parse(args, strict: [level: :string])
    level = parsed[:level]
    version = Mix.Project.config()[:version]

    with {:ok, new_version} <- bump(version, level),
         {:ok, _} <- confirm_changes(new_version),
         {:ok, _} <- update_version(new_version),
         {:ok, _} <- commit_changes(new_version),
         {:ok, _} <- push_changes(),
         {:ok, _} <- create_tag(new_version),
         {:ok, _} <- push_tag(new_version) do
      IO.puts("Bumped version from #{version} to #{new_version}")
      :ok
    else
      {:error, reason} -> IO.puts(reason)
    end
  end

  defp confirm_changes(new_version) do
    IO.puts("Bumping version from #{Mix.Project.config()[:version]} to #{new_version}")
    IO.puts("Continue? (y/n)")

    case IO.gets("") do
      "y\n" -> {:ok, new_version}
      _ -> {:error, "Aborted"}
    end
  end

  defp check_master_branch() do
    IO.puts("Checking current branch")
    current_branch = System.cmd("git", ["branch", "--show-current"])

    case current_branch do
      {"master\n", _} -> {:ok, current_branch}
      {_, _} -> raise "Not on master branch"
    end
  end

  defp push_tag(new_version) do
    IO.puts("Pushing tag #{new_version}")
    system("git push origin #{new_version}")
    {:ok, new_version}
  end

  defp create_tag(new_version) do
    IO.puts("Creating tag #{new_version}")
    system("git tag -a #{new_version} -m \"Version #{new_version}\"")
    {:ok, new_version}
  end

  defp push_changes() do
    IO.puts("Pushing changes")
    system("git push origin master")
    {:ok, "Pushed changes"}
  end

  defp commit_changes(new_version) do
    IO.puts("Committing changes")
    system("git add #{File.cwd!()}/mix.exs")
    system("git commit -m\"Bump version to #{new_version}\"")
    {:ok, "Committed changes"}
  end

  defp system(command) do
    system_result = System.cmd("sh", ["-c", command])

    case system_result do
      {_, 0} -> :ok
      {0, _} -> :ok
      {_, _} -> raise "Command failed: #{command}"
    end
  end

  defp update_version(new_version) do
    IO.puts("Updating version to #{new_version}")
    mix_exs = File.read!("mix.exs")

    new_mix_exs =
      Regex.replace(~r/version: \"\d+\.\d+\.\d+\"/, mix_exs, "version: \"#{new_version}\"")

    File.write!("mix.exs", new_mix_exs)
    {:ok, new_version}
  end

  defp bump(version, level) do
    case level do
      "major" -> {:ok, bump_major(version)}
      "minor" -> {:ok, bump_minor(version)}
      "patch" -> {:ok, bump_patch(version)}
      _ -> {:error, "Invalid bump level"}
    end
  end

  defp bump_major(version) do
    [major, _minor, _patch] = version |> String.split(".") |> Enum.map(&String.to_integer/1)
    [major + 1, 0, 0] |> Enum.join(".")
  end

  defp bump_minor(version) do
    [major, minor, _patch] = version |> String.split(".") |> Enum.map(&String.to_integer/1)
    [major, minor + 1, 0] |> Enum.join(".")
  end

  defp bump_patch(version) do
    [major, minor, patch] = version |> String.split(".") |> Enum.map(&String.to_integer/1)
    [major, minor, patch + 1] |> Enum.join(".")
  end
end
