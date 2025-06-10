-module(pg16_erlang27_test).
-export([run/0, test_connection/0, test_query/0]).

%% Test module for PostgreSQL 16.1 compatibility with Erlang 27.3 
%% using the patched epgsql-1 library

run() ->
    io:format("Starting PostgreSQL 16.1 compatibility test with Erlang 27.3~n"),
    % Test basic connection
    case test_connection() of
        {ok, C} ->
            % Test a query if connection succeeds
            Result = test_query(C),
            % Close connection
            epgsql:close(C),
            {ok, Result};
        Error ->
            Error
    end.

%% Test connection to PostgreSQL 16.1
test_connection() ->
    io:format("Testing connection to PostgreSQL 16.1...~n"),
    
    % Connection parameters
    Host = "localhost",
    Username = "sqerl",
    Password = "sqerl",
    Database = "sqerl_test",
    
    % Display connection info
    io:format("Connection parameters:~n"),
    io:format("Host: ~s~n", [Host]),
    io:format("Username: ~s~n", [Username]),
    io:format("Database: ~s~n", [Database]),
    
    % Try to connect using the modified epgsql library
    try epgsql:connect(Host, Username, Password, [{database, Database}]) of
        {ok, C} = Success ->
            io:format("Successfully connected to PostgreSQL 16.1!~n"),
            Success;
        Error ->
            io:format("Connection failed: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stacktrace ->
            io:format("Connection error: ~p:~p~n", [Error, Reason]),
            io:format("Stacktrace: ~p~n", [Stacktrace]),
            {error, {Error, Reason}}
    end.

%% Test a simple query
test_query() ->
    case test_connection() of
        {ok, C} ->
            Result = test_query(C),
            epgsql:close(C),
            Result;
        Error ->
            Error
    end.

%% Execute a test query
test_query(C) ->
    io:format("Testing query execution...~n"),
    
    % Simple version query
    Query = "SELECT version();",
    io:format("Executing query: ~s~n", [Query]),
    
    try epgsql:squery(C, Query) of
        {ok, Columns, Rows} = Success ->
            io:format("Query successful!~n"),
            io:format("Result: ~n"),
            print_query_result(Columns, Rows),
            Success;
        Error ->
            io:format("Query failed: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stacktrace ->
            io:format("Query error: ~p:~p~n", [Error, Reason]),
            io:format("Stacktrace: ~p~n", [Stacktrace]),
            {error, {Error, Reason}}
    end.

%% Print formatted query result
print_query_result(Columns, Rows) ->
    % Print column headers
    ColumnNames = [binary_to_list(C#column.name) || C <- Columns],
    io:format("~s~n", [string:join(ColumnNames, " | ")]),
    
    % Print separator line
    SepLine = lists:duplicate(lists:sum([length(C) + 3 || C <- ColumnNames]), "-"),
    io:format("~s~n", [SepLine]),
    
    % Print each row
    lists:foreach(fun(Row) ->
        RowValues = [format_value(V) || V <- tuple_to_list(Row)],
        io:format("~s~n", [string:join(RowValues, " | ")])
    end, Rows).

%% Format a value for display
format_value(null) -> "NULL";
format_value(V) when is_binary(V) -> binary_to_list(V);
format_value(V) -> io_lib:format("~p", [V]).
