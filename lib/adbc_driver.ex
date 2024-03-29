defmodule Adbc.Driver do
  @moduledoc false

  alias Adbc.Helper
  require Logger

  # == GENERATED CONSTANTS ==

  # Generated by update.exs at 2024-03-29T00:42:43. Do not change manually.
  @generated_driver_versions %{
    sqlite: "0.11.0",
    postgresql: "0.11.0",
    flightsql: "0.11.0",
    snowflake: "0.11.0"
  }
  @generated_driver_data %{
    sqlite: %{
      "aarch64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_sqlite-0.11.0-py3-none-macosx_11_0_arm64.whl"
      },
      "aarch64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_sqlite-0.11.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
      },
      "x86_64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_sqlite-0.11.0-py3-none-macosx_10_15_x86_64.whl"
      },
      "x86_64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_sqlite-0.11.0-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
      },
      "x86_64-windows-msvc" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_sqlite-0.11.0-py3-none-win_amd64.whl"
      }
    },
    postgresql: %{
      "aarch64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_postgresql-0.11.0-py3-none-macosx_11_0_arm64.whl"
      },
      "aarch64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_postgresql-0.11.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
      },
      "x86_64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_postgresql-0.11.0-py3-none-macosx_10_15_x86_64.whl"
      },
      "x86_64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_postgresql-0.11.0-py3-none-manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
      },
      "x86_64-windows-msvc" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_postgresql-0.11.0-py3-none-win_amd64.whl"
      }
    },
    flightsql: %{
      "aarch64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_flightsql-0.11.0-py3-none-macosx_11_0_arm64.whl"
      },
      "aarch64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_flightsql-0.11.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
      },
      "x86_64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_flightsql-0.11.0-py3-none-macosx_10_15_x86_64.whl"
      },
      "x86_64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_flightsql-0.11.0-py3-none-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
      },
      "x86_64-windows-msvc" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_flightsql-0.11.0-py3-none-win_amd64.whl"
      }
    },
    snowflake: %{
      "aarch64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_snowflake-0.11.0-py3-none-macosx_11_0_arm64.whl"
      },
      "aarch64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_snowflake-0.11.0-py3-none-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
      },
      "x86_64-apple-darwin" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_snowflake-0.11.0-py3-none-macosx_10_15_x86_64.whl"
      },
      "x86_64-linux-gnu" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_snowflake-0.11.0-py3-none-manylinux_2_5_x86_64.manylinux1_x86_64.manylinux_2_17_x86_64.manylinux2014_x86_64.whl"
      },
      "x86_64-windows-msvc" => %{
        url:
          "https://github.com/apache/arrow-adbc/releases/download/apache-arrow-adbc-0.11.0-rc0/adbc_driver_snowflake-0.11.0-py3-none-win_amd64.whl"
      }
    }
  }

  # == GENERATED CONSTANTS ==

  @driver_versions @generated_driver_versions
  @driver_data @generated_driver_data

  def download(driver_name, opts \\ []) when is_atom(driver_name) and is_list(opts) do
    case find_driver(driver_name) do
      {:ok, default_version} ->
        url = opts[:url]
        version = opts[:version] || default_version
        ignore_proxy = opts[:ignore_proxy] || false

        with {:ok, triplet} <- current_triplet(),
             :missing <- driver_status(driver_name, version, triplet),
             {:ok, url} <- driver_wheel(url, driver_name, version == default_version, triplet),
             {:ok, cache_path} <-
               cached_download(url, ignore_proxy, driver_name, version, triplet) do
          extract!(cache_path, driver_name, version, triplet)
        end

      {:missing, known} ->
        {:error, "unknown driver #{inspect(driver_name)}, expected one of #{known}"}
    end
  end

  defp find_driver(driver_name) do
    case @driver_versions do
      %{^driver_name => version} ->
        {:ok, version}

      %{} ->
        {:missing,
         @driver_versions |> Map.keys() |> Enum.sort() |> Enum.map_join(", ", &inspect/1)}
    end
  end

  defp current_triplet do
    current_target(:os.type())
  end

  defp driver_status(driver_name, version, triplet) do
    if File.exists?(adbc_driver_so(driver_name, version, triplet)) do
      :ok
    else
      :missing
    end
  end

  defp current_target({:win32, _}) do
    processor_architecture =
      String.downcase(String.trim(System.get_env("PROCESSOR_ARCHITECTURE")))

    # https://docs.microsoft.com/en-gb/windows/win32/winprog64/wow64-implementation-details?redirectedfrom=MSDN
    partial_triplet =
      case processor_architecture do
        "amd64" -> "x86_64-windows-"
        "ia64" -> "ia64-windows-"
        "arm64" -> "aarch64-windows-"
        "x86" -> "x86-windows-"
      end

    {compiler, _} = :erlang.system_info(:c_compiler_used)

    case compiler do
      :msc -> {:ok, partial_triplet <> "msvc"}
      :gnuc -> {:ok, partial_triplet <> "gnu"}
      other -> {:ok, partial_triplet <> Atom.to_string(other)}
    end
  end

  defp current_target({:unix, type}) do
    # get current target triplet from `:erlang.system_info/1`
    system_architecture = to_string(:erlang.system_info(:system_architecture))

    case String.split(system_architecture, "-", trim: true) do
      [arch, _vendor, os, distro] ->
        {:ok, "#{arch}-#{os}-#{distro}"}

      [arch, vendor, "darwin" <> _] when type == :darwin ->
        {:ok, "#{arch}-#{vendor}-darwin"}

      [_, _, _] ->
        {:ok, system_architecture}

      _ ->
        {:error, "cannot decide current target"}
    end
  end

  defp driver_wheel(url, _driver_name, _default_version?, _triplet) when is_binary(url) do
    {:ok, url}
  end

  defp driver_wheel(_url, _driver_name, false, triplet) do
    {:error,
     "when passing a custom version for a driver, you must also specify the :url to find the precompiled version for `#{triplet}`"}
  end

  defp driver_wheel(_url, driver_name, _default_version, triplet) do
    case @driver_data do
      %{^driver_name => %{^triplet => %{url: url}}} -> {:ok, url}
      %{} -> {:error, "official driver does not have a precompiled version for `#{triplet}`"}
    end
  end

  defp cached_download(url, ignore_proxy, driver_name, version, triplet) do
    cache_dir = adbc_cache_dir()
    cache_path = Path.join(cache_dir, "#{driver_name}-#{triplet}-#{version}.zip")

    if File.exists?(cache_path) do
      {:ok, cache_path}
    else
      Logger.debug("Downloading Adbc driver for #{driver_name} from #{url}...")

      with {:ok, body} <- Helper.download(url, ignore_proxy) do
        File.mkdir_p!(cache_dir)
        File.write!(cache_path, body)
        {:ok, cache_path}
      end
    end
  end

  defp adbc_cache_dir do
    if dir = System.get_env("ADBC_CACHE_DIR") do
      Path.expand(dir)
    else
      :filename.basedir(:user_cache, "adbc")
    end
  end

  defp extract!(cache_path, driver_name, version, triplet) do
    adbc_so_priv_dir = adbc_so_priv_dir()
    File.mkdir_p!(adbc_so_priv_dir)

    cache_path = String.to_charlist(cache_path)
    {:ok, zip_handle} = :zip.zip_open(cache_path, [:memory])
    {:ok, zip_files} = :zip.table(cache_path)

    for {:zip_file, filename, _, _, _, _} <- zip_files,
        Path.extname(filename) == ".so" do
      {:ok, {filename, file_data}} = :zip.zip_get(filename, zip_handle)

      filename =
        String.replace_leading(
          to_string(filename),
          "adbc_driver_#{driver_name}/",
          "#{triplet}-#{version}-"
        )

      filepath = Path.join(adbc_so_priv_dir, filename)
      File.write!(filepath, file_data)
    end

    :ok = :zip.zip_close(zip_handle)
  end

  def so_path(driver_name, opts \\ [])

  def so_path(driver_name, opts) when is_atom(driver_name) do
    case find_driver(driver_name) do
      {:ok, default_version} ->
        version = opts[:version] || default_version

        case current_triplet() do
          {:ok, triplet} ->
            expected_filepath = adbc_driver_so(driver_name, version, triplet)

            if File.exists?(expected_filepath) do
              {:ok, expected_filepath}
            else
              {:error,
               "driver #{driver_name} is not available (see Adbc moduledocs to learn how to install a driver)"}
            end

          {:error, reason} ->
            {:error, reason}
        end

      {:missing, known} ->
        {:error,
         "unknown driver #{inspect(driver_name)}, expected one of #{known} or a string representing the full path to a driver"}
    end
  end

  def so_path(driver_name, _opts) when is_binary(driver_name) do
    {:ok, driver_name}
  end

  defp adbc_driver_so(driver_name, version, triplet) do
    Path.join(
      adbc_so_priv_dir(),
      "#{triplet}-#{version}-libadbc_driver_#{driver_name}.so"
    )
  end

  defp adbc_so_priv_dir do
    case :os.type() do
      {:win32, _} -> Application.app_dir(:adbc, "priv/bin")
      _ -> Application.app_dir(:adbc, "priv/lib")
    end
  end
end
