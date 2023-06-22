defmodule Adbc.Connection do
  @moduledoc """
  Documentation for `Adbc.Connection`.
  """

  @type t :: GenServer.server()

  use GenServer
  import Adbc.Helper, only: [error_to_exception: 1]

  @doc """
  TODO.
  """
  def start_link(opts) do
    {db, opts} = Keyword.pop(opts, :database, nil)

    unless db do
      raise ArgumentError, ":database option must be specified"
    end

    {process_options, opts} = Keyword.pop(opts, :process_options, [])

    with {:ok, conn} <- Adbc.Nif.adbc_connection_new(),
         :ok <- init_options(conn, opts) do
      GenServer.start_link(__MODULE__, {db, conn}, process_options)
    else
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  defp init_options(ref, opts) do
    Enum.reduce_while(opts, :ok, fn {key, value}, :ok ->
      case Adbc.Nif.adbc_connection_set_option(ref, to_string(key), to_string(value)) do
        :ok -> {:cont, :ok}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  @doc """
  Get metadata about the database/driver.

  The result is an Arrow dataset with the following schema:

  Field Name                  | Field Type
  ----------------------------|------------------------
  info_name                   | uint32 not null
  info_value                  | INFO_SCHEMA

  `INFO_SCHEMA` is a dense union with members:

  Field Name (Type Code)      | Field Type
  ----------------------------|------------------------
  string_value (0)            | utf8
  bool_value (1)              | bool
  int64_value (2)             | int64
  int32_bitmask (3)           | int32
  string_list (4)             | list<utf8>
  int32_to_int32_list_map (5) | map<int32, list<int32>>

  Each metadatum is identified by an integer code. The recognized
  codes are defined as constants. Codes [0, 10_000) are reserved
  for ADBC usage. Drivers/vendors will ignore requests for
  unrecognized codes (the row will be omitted from the result).
  """
  @spec get_info(t(), list(non_neg_integer())) ::
          {:ok, Adbc.ArrowArrayStream.t()} | {:error, Exception.t()}
  def get_info(conn, info_codes \\ []) when is_list(info_codes) do
    case GenServer.call(conn, {:get_info, info_codes}, :infinity) do
      {:ok, ref} -> {:ok, %Adbc.ArrowArrayStream{reference: ref}}
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  @doc """
  Get a hierarchical view of all catalogs, database schemas, tables, and columns.

  The result is an Arrow dataset with the following schema:

  | Field Name               | Field Type              |
  |--------------------------|-------------------------|
  | catalog_name             | utf8                    |
  | catalog_db_schemas       | list<DB_SCHEMA_SCHEMA>  |

  `DB_SCHEMA_SCHEMA` is a Struct with fields:

  | Field Name               | Field Type              |
  |--------------------------|-------------------------|
  | db_schema_name           | utf8                    |
  | db_schema_tables         | list<TABLE_SCHEMA>      |

  `TABLE_SCHEMA` is a Struct with fields:

  | Field Name               | Field Type              |
  |--------------------------|-------------------------|
  | table_name               | utf8 not null           |
  | table_type               | utf8 not null           |
  | table_columns            | list<COLUMN_SCHEMA>     |
  | table_constraints        | list<CONSTRAINT_SCHEMA> |

  `COLUMN_SCHEMA` is a Struct with fields:

  | Field Name               | Field Type              | Comments |
  |--------------------------|-------------------------|----------|
  | column_name              | utf8 not null           |          |
  | ordinal_position         | int32                   | (1)      |
  | remarks                  | utf8                    | (2)      |
  | xdbc_data_type           | int16                   | (3)      |
  | xdbc_type_name           | utf8                    | (3)      |
  | xdbc_column_size         | int32                   | (3)      |
  | xdbc_decimal_digits      | int16                   | (3)      |
  | xdbc_num_prec_radix      | int16                   | (3)      |
  | xdbc_nullable            | int16                   | (3)      |
  | xdbc_column_def          | utf8                    | (3)      |
  | xdbc_sql_data_type       | int16                   | (3)      |
  | xdbc_datetime_sub        | int16                   | (3)      |
  | xdbc_char_octet_length   | int32                   | (3)      |
  | xdbc_is_nullable         | utf8                    | (3)      |
  | xdbc_scope_catalog       | utf8                    | (3)      |
  | xdbc_scope_schema        | utf8                    | (3)      |
  | xdbc_scope_table         | utf8                    | (3)      |
  | xdbc_is_autoincrement    | bool                    | (3)      |
  | xdbc_is_generatedcolumn  | bool                    | (3)      |

  1. The column's ordinal position in the table (starting from 1).
  2. Database-specific description of the column.
  3. Optional value. Should be null if not supported by the driver.
     xdbc_ values are meant to provide JDBC/ODBC-compatible metadata
     in an agnostic manner.

  `CONSTRAINT_SCHEMA` is a Struct with fields:

  | Field Name               | Field Type              | Comments |
  |--------------------------|-------------------------|----------|
  | constraint_name          | utf8                    |          |
  | constraint_type          | utf8 not null           | (1)      |
  | constraint_column_names  | list<utf8> not null     | (2)      |
  | constraint_column_usage  | list<USAGE_SCHEMA>      | (3)      |

  1. One of 'CHECK', 'FOREIGN KEY', 'PRIMARY KEY', or 'UNIQUE'.
  2. The columns on the current table that are constrained, in order.
  3. For FOREIGN KEY only, the referenced table and columns.

  `USAGE_SCHEMA` is a Struct with fields:

  | Field Name               | Field Type              |
  |--------------------------|-------------------------|
  | fk_catalog               | utf8                    |
  | fk_db_schema             | utf8                    |
  | fk_table                 | utf8 not null           |
  | fk_column_name           | utf8 not null           |
  """
  @spec get_objects(t(), non_neg_integer(),
          catalog: String.t(),
          db_schema: String.t(),
          table_name: String.t(),
          table_type: [String.t()],
          column_name: String.t()
        ) :: {:ok, Adbc.ArrowArrayStream.t()} | {:error, Exception.t()}
  def get_objects(conn, depth, opts \\ [])
      when is_integer(depth) and depth >= 0 do
    opts = Keyword.validate!(opts, [:catalog, :db_schema, :table_name, :table_type, :column_name])

    case GenServer.call(conn, {:get_objects, depth, opts}, :infinity) do
      {:ok, ref} -> {:ok, %Adbc.ArrowArrayStream{reference: ref}}
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  @doc """
  Get a list of table types in the database.

  The result is an Arrow dataset with the following schema:

  Field Name     | Field Type
  ---------------|--------------
  table_type     | utf8 not null
  """
  @spec get_table_types(t) ::
          {:ok, Adbc.ArrowArrayStream.t()} | {:error, Exception.t()}
  def get_table_types(conn) do
    case GenServer.call(conn, :get_table_types, :infinity) do
      {:ok, ref} -> {:ok, %Adbc.ArrowArrayStream{reference: ref}}
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  @doc """
  Get the Arrow schema of a table.
  """
  @spec get_table_schema(t, String.t() | nil, String.t() | nil, String.t()) ::
          {:ok, Adbc.ArrowSchema.t()} | {:error, Exception.t()}
  def get_table_schema(conn, catalog, db_schema, table_name)
      when (is_binary(catalog) or catalog == nil) and (is_binary(db_schema) or catalog == nil) and
             is_binary(table_name) do
    case GenServer.call(conn, {:get_table_schema, catalog, db_schema, table_name}, :infinity) do
      {:ok, schema_ref} -> {:ok, %Adbc.ArrowSchema{reference: schema_ref}}
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  @doc """
  Commit any pending transactions. Only used if autocommit is disabled.

  Behavior is undefined if this is mixed with SQL transaction statements.
  """
  @spec commit(Adbc.Connection.t()) :: :ok | {:error, Exception.t()}
  def commit(server) do
    case GenServer.call(server, :commit, :infinity) do
      :ok -> :ok
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  @doc """
  Roll back any pending transactions. Only used if autocommit is disabled.

  Behavior is undefined if this is mixed with SQL transaction statements.
  """
  @spec rollback(Adbc.Connection.t()) :: :ok | {:error, Exception.t()}
  def rollback(server) do
    case GenServer.call(server, :rollback, :infinity) do
      :ok -> :ok
      {:error, reason} -> {:error, error_to_exception(reason)}
    end
  end

  ## Callbacks

  @impl true
  def init({db, conn}) do
    case GenServer.call(db, {:initialize_connection, conn}, :infinity) do
      :ok ->
        Process.flag(:trap_exit, true)
        {:ok, %{conn: conn}}

      {:error, reason} ->
        {:stop, error_to_exception(reason)}
    end
  end

  @impl true
  def handle_call({:get_info, info_codes}, _from, state) do
    {:reply, Adbc.Nif.adbc_connection_get_info(state.conn, info_codes), state}
  end

  @impl true
  def handle_call({:get_objects, depth, opts}, _from, state) do
    result =
      Adbc.Nif.adbc_connection_get_objects(
        state.conn,
        depth,
        opts[:catalog],
        opts[:db_schema],
        opts[:table_name],
        opts[:table_type],
        opts[:column_name]
      )

    {:reply, result, state}
  end

  @impl true
  def handle_call(:get_table_types, _from, state) do
    {:reply, Adbc.Nif.adbc_connection_get_table_types(state.conn), state}
  end

  @impl true
  def handle_call({:get_table_schema, catalog, db_schema, table_name}, _from, state) do
    result = Adbc.Nif.adbc_connection_get_table_schema(state.conn, catalog, db_schema, table_name)
    {:reply, result, state}
  end

  @impl true
  def handle_call(:commit, _from, state) do
    {:reply, Adbc.Nif.adbc_connection_commit(state.conn), state}
  end

  @impl true
  def handle_call(:rollback, _from, state) do
    {:reply, Adbc.Nif.adbc_connection_rollback(state.conn), state}
  end

  @impl true
  def handle_info({:EXIT, _db, reason}, state), do: {:stop, reason, state}
  def handle_info(_msg, state), do: {:noreply, state}

  @impl true
  def terminate(_reason, state) do
    Adbc.Nif.adbc_connection_release(state.conn)
    :ok
  end
end
