# To support a new version of ADBC, you must:
#
# 1. Update the contents in 3rd_party with latest (only root files and c/)
#    from latest ADBC release: https://github.com/apache/arrow-adbc/releases/
# 2. Update @duckdb_version, @adbc_driver_version, and @adbc_tag below
# 3. Run elixir update.exs
# 4. ???
# 5. Profit!
#
Mix.install([{:req, "~> 0.4"}])

defmodule Update do
  # To update duckdb driver, just bump this version
  # https://github.com/duckdb/duckdb/releases/
  @duckdb_version "1.0.0"

  # To update ADBC drivers, bump the tag and version accordingly
  # https://github.com/apache/arrow-adbc/releases
  @adbc_driver_version "1.1.0"
  @adbc_tag "apache-arrow-adbc-13"
  @adbc_drivers ~w(sqlite postgresql flightsql snowflake)a

  def versions do
    Map.new(@adbc_drivers, &{&1, @adbc_driver_version})
    |> Map.merge(%{duckdb: @duckdb_version})
  end

  def mappings do
    %{}
    |> Map.merge(adbc_mappings(@adbc_driver_version, @adbc_tag))
    |> Map.merge(duckdb_mappings(@duckdb_version))
  end

  defp duckdb_mappings(duckdb_version) do
    assets =
      fetch_assets!("https://api.github.com/repos/duckdb/duckdb/releases/tags/v#{duckdb_version}")

    IO.puts("Generating duckdb")

    zip_files =
      Enum.filter(assets, fn %{"name" => name} ->
        String.starts_with?(name, "libduckdb") and String.ends_with?(name, ".zip") and
          not String.contains?(name, "src")
      end)

    {aarch64_apple_darwin, zip_files} = data_for(zip_files, ["osx", "universal"])
    {x86_64_apple_darwin, zip_files} = {aarch64_apple_darwin, zip_files}
    {aarch64_linux_gnu, zip_files} = data_for(zip_files, ["linux", "aarch64"])
    {x86_64_linux_gnu, zip_files} = data_for(zip_files, ["linux", "amd64"])
    {x86_64_windows_msvc, zip_files} = data_for(zip_files, ["windows", "amd64"])

    if zip_files != [] do
      IO.puts("The following zip files for duckdb are not being used:\n\n#{inspect(zip_files)}")
    end

    %{
      duckdb: %{
        "aarch64-apple-darwin" => aarch64_apple_darwin,
        "x86_64-apple-darwin" => x86_64_apple_darwin,
        "aarch64-linux-gnu" => aarch64_linux_gnu,
        "x86_64-linux-gnu" => x86_64_linux_gnu,
        "x86_64-windows-msvc" => x86_64_windows_msvc
      }
    }
  end

  defp adbc_mappings(version, tag) do
    assets = fetch_assets!("https://api.github.com/repos/apache/arrow-adbc/releases/tags/#{tag}")

    for driver <- @adbc_drivers, into: %{} do
      IO.puts("Generating #{driver}")
      prefix = "adbc_driver_#{driver}-#{version}"
      suffix = ".whl"

      wheels =
        Enum.filter(assets, fn %{"name" => name} ->
          String.starts_with?(name, prefix) and String.ends_with?(name, suffix)
        end)

      {aarch64_apple_darwin, wheels} = data_for(wheels, ["macosx", "arm64"])
      {x86_64_apple_darwin, wheels} = data_for(wheels, ["macosx", "x86_64"])
      {aarch64_linux_gnu, wheels} = data_for(wheels, ["manylinux", "aarch64"])
      {x86_64_linux_gnu, wheels} = data_for(wheels, ["manylinux", "x86_64"])
      {x86_64_windows_msvc, wheels} = data_for(wheels, ["win_amd64"])

      if wheels != [] do
        IO.puts("The following wheels for #{driver} are not being used:\n\n#{inspect(wheels)}")
      end

      data =
        %{
          "aarch64-apple-darwin" => aarch64_apple_darwin,
          "x86_64-apple-darwin" => x86_64_apple_darwin,
          "aarch64-linux-gnu" => aarch64_linux_gnu,
          "x86_64-linux-gnu" => x86_64_linux_gnu,
          "x86_64-windows-msvc" => x86_64_windows_msvc
        }

      {driver, data}
    end
  end

  defp data_for(wheels, parts) do
    case Enum.split_with(wheels, fn %{"name" => name} -> Enum.all?(parts, &(name =~ &1)) end) do
      {[%{"browser_download_url" => url}], rest} -> {%{url: url}, rest}
      {[], _rest} -> raise "no entries matching #{inspect(parts)}\n\n#{inspect(wheels)}"
      {_, _rest} -> raise "many entries matching #{inspect(parts)}\n\n#{inspect(wheels)}"
    end
  end

  defp fetch_assets!(url) do
    opts =
      if token = System.get_env("GITHUB_TOKEN") do
        [auth: {:bearer, token}]
      else
        []
      end

    release = Req.get!(url, opts)

    if release.status != 200 do
      raise "unknown GitHub release #{url}\n\n#{inspect(release)}"
    end

    release.body["assets"]
  end
end

file = "lib/adbc_driver.ex"
versions = Update.versions()
mappings = Update.mappings()

case String.split(File.read!(file), "# == GENERATED CONSTANTS ==") do
  [pre, _mid, post] ->
    time =
      NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second) |> NaiveDateTime.to_iso8601()

    mid = """
    # == GENERATED CONSTANTS ==

    # Generated by update.exs at #{time}. Do not change manually.
    @generated_driver_versions #{inspect(versions)}
    @generated_driver_data #{inspect(mappings)}

    # == GENERATED CONSTANTS ==
    """

    File.write!(file, [Code.format_string!(pre <> mid <> post), "\n"])

  _ ->
    raise "could not find # == GENERATED CONSTANTS == chunks in #{file}"
end
