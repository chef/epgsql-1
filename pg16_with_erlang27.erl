-module(pg16_with_erlang27).
-export([run/0, test_connection/0]).

% Simple module to verify connectivity with PostgreSQL 16 using Erlang 27.3
% Works around the case_clause error in epgsql

% Main entry point
run() ->
    compile:file(pg16_with_erlang27),
    test_connection().

% Test connection to PostgreSQL 16
test_connection() ->
    io:format("Testing connection to PostgreSQL 16 with Erlang 27.3~n"),
    
    % Use the old-style connection approach that has worked in previous Erlang versions
    ConnectResult = connect_with_retry(),
    
    case ConnectResult of
        {ok, C} ->
            io:format("Successfully connected to PostgreSQL 16~n"),
            % Run a simple version query
            Result = run_query(C, "SELECT version()"),
            % Close connection
            epgsql:close(C),
            {ok, Result};
        Error ->
            io:format("Failed to connect to PostgreSQL: ~p~n", [Error]),
            Error
    end.

% Use the old-style connection approach with fallback handling
connect_with_retry() ->
    io:format("Attempting to connect to PostgreSQL 16...~n"),
    % Use the old-style connection method which is more stable
    Host = "localhost",
    Username = "sqerl",
    Password = "sqerl",
    % Don't use tcp_opts here - use allowed options only
    Options = [
        {database, "sqerl_test"},
        {port, 5432},
        {timeout, 5000}
    ],
    
    % Start a connection process
    {ok, C} = epgsql_sock:start_link(),
    
    % Use process dictionary to catch the unexpected response format
    % This is a hack to handle the case_clause issue in Erlang 27.3
    put(pg16_conn_pid, C),
    
    % Try the standard connection method
    ConnectResult = try epgsql:connect(C, Host, Username, Password, Options)
                    catch
                        error:{case_clause, {active, Pid}} when is_pid(Pid) ->
                            % Manually handle the case that's causing issues in Erlang 27.3
                            io:format("Caught case_clause error, using manual handling~n"),
                            % Wait for the actual connection result
                            receive
                                {epgsql, Pid, connected} -> {ok, C};
                                {epgsql, Pid, Error} -> Error
                            after 5000 ->
                                {error, timeout}
                            end;
                        Error:Reason ->
                            {error, {Error, Reason}}
                    end,
    
    % Return connection result
    ConnectResult.

% Run a simple query on the connection
run_query(C, Query) ->
    try epgsql:squery(C, Query) of
        {ok, Columns, Rows} ->
            io:format("Query successful:~n"),
            io:format("Columns: ~p~n", [Columns]),
            io:format("Rows: ~p~n", [Rows]),
            {columns_and_rows, Columns, Rows};
        {ok, Count} ->
            io:format("Query affected ~p rows~n", [Count]),
            {affected_rows, Count};
        {ok, Count, Columns, Rows} ->
            io:format("Query returned ~p rows~n", [Count]),
            io:format("Columns: ~p~n", [Columns]),
            io:format("Rows: ~p~n", [Rows]),
            {count_columns_and_rows, Count, Columns, Rows};
        Error ->
            io:format("Query error: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stacktrace ->
            io:format("Exception during query:~n~p:~p~n~p~n", [Error, Reason, Stacktrace]),
            {error, {Error, Reason}}
    end.
