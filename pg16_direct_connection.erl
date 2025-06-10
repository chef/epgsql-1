-module(pg16_direct_connection).
-export([run/0, start/0, test_query/0]).

% This module bypasses epgsql:connect and implements a direct connection to PostgreSQL 16
% Works around the case_clause error in Erlang 27.3

% Start function for direct use from command line
start() ->
    compile:file(pg16_direct_connection),
    run().

% Main run function
run() ->
    test_query().

% Test a direct connection and query to PostgreSQL 16
test_query() ->
    io:format("Connecting to PostgreSQL 16 using Erlang 27.3~n"),
    case connect() of
        {ok, C} ->
            io:format("Successfully connected to PostgreSQL 16~n"),
            case direct_query(C, "SELECT version()") of
                {ok, Cols, Rows} ->
                    io:format("PostgreSQL version: ~p~n", [{Cols, Rows}]),
                    ok = close(C),
                    {ok, Rows};
                Error ->
                    io:format("Query error: ~p~n", [Error]),
                    ok = close(C),
                    Error
            end;
        Error ->
            io:format("Connection error: ~p~n", [Error]),
            Error
    end.

% Direct connection function that avoids the problematic epgsql:connect
connect() ->
    % Start a new connection process
    {ok, C} = epgsql_sock:start_link(),
    
    % Use gen_server:call directly to avoid the problematic code in epgsql.erl
    Options = #{
        host => "localhost",
        username => "postgres", % Change as needed
        password => "postgres", % Change as needed
        database => "postgres", % Change as needed
        port => 5432
    },
    
    % Set a connection timeout
    Timeout = 5000,
    
    % Make the direct call to the socket process
    case gen_server:call(C, {command, epgsql_cmd_connect, Options}, Timeout) of
        % This is the case that causes issues in Erlang 27.3
        {active, Pid} when is_pid(Pid) ->
            % Wait for the connection to complete or fail
            receive
                {epgsql, Pid, connected} -> 
                    io:format("Connection successful via {active, Pid} path~n"),
                    {ok, C};
                {epgsql, Pid, Error} -> 
                    io:format("Connection failed: ~p~n", [Error]),
                    Error
            after Timeout ->
                {error, timeout}
            end;
        % Standard case for older Erlang versions
        connected ->
            io:format("Connection successful via standard path~n"),
            {ok, C};
        Error ->
            io:format("Connection error: ~p~n", [Error]),
            Error
    end.

% Execute a query directly using the socket process
direct_query(C, Query) ->
    % Use gen_server:call directly to avoid any potential issues
    case gen_server:call(C, {command, epgsql_cmd_squery, Query}, 5000) of
        {active, Pid} when is_pid(Pid) ->
            % Handle the Erlang 27.3 case
            receive
                {epgsql, Pid, {columns, Cols}} ->
                    receive
                        {epgsql, Pid, {data, Rows}} ->
                            receive
                                {epgsql, Pid, {complete, _}} ->
                                    {ok, Cols, Rows};
                                {epgsql, Pid, Error} ->
                                    Error
                            after 5000 ->
                                {error, timeout}
                            end;
                        {epgsql, Pid, Error} ->
                            Error
                    after 5000 ->
                        {error, timeout}
                    end;
                {epgsql, Pid, Error} ->
                    Error
            after 5000 ->
                {error, timeout}
            end;
        % Standard response pattern
        {ok, Cols, Rows} ->
            {ok, Cols, Rows};
        Error ->
            Error
    end.

% Close the connection
close(C) ->
    epgsql_sock:close(C).
