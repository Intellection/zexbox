defmodule Mix.Tasks.Bump do
  @moduledoc """
  Bump version number in mix.exs and create a new git tag.
  """

  @spec run([binary]) :: :ok
  def run(args) do
    check_main_branch()
    {parsed, _, _} = OptionParser.parse(args, strict: [level: :string])
    level = parsed[:level]
    version = Mix.Project.config()[:version]
    new_version = bump(version, level)
    confirm_changes(new_version)
    update_version(new_version)
    commit_changes(new_version)
    push_changes()
    create_tag(new_version)
    push_tag(new_version)
  end

  defp confirm_changes(new_version) do
    IO.puts("Bumping version from #{Mix.Project.config()[:version]} to #{new_version}")
    IO.puts("Continue? (y/n)")

    case IO.gets("") do
      "y\n" -> :ok
      _ -> raise "Aborted"
    end
  end

  defp check_main_branch() do
    IO.puts("Checking current branch")
    current_branch = System.cmd("git", ["branch", "--show-current"])

    case current_branch do
      {"main\n", _} -> :ok
      {_, _} -> raise "Not on main branch"
    end
  end

  defp push_tag(new_version) do
    IO.puts("Pushing tag #{new_version}")
    system("git push origin #{new_version}")
  end

  defp create_tag(new_version) do
    IO.puts("Creating tag #{new_version}")
    system("git tag -a #{new_version} -m \"Version #{new_version}\"")
  end

  defp push_changes() do
    IO.puts("Pushing changes")
    system("git push origin main")
  end

  defp commit_changes(new_version) do
    IO.puts("Committing changes")
    system("git add mix.exs")
    system("git commit -m \"Bump version to #{new_version}\"")
  end

  defp system(command) do
    case System.cmd("sh", ["-c", command]) do
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
  end

  defp bump(version, level) do
    case level do
      "major" -> bump_major(version)
      "minor" -> bump_minor(version)
      "patch" -> bump_patch(version)
      _ -> raise "Invalid bump level"
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
