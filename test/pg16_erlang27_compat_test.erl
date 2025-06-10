%%%-------------------------------------------------------------------
%%% @doc
%%% Test module specifically for PostgreSQL 16.1 with Erlang 27.3 compatibility
%%% @end
%%%-------------------------------------------------------------------
-module(pg16_erlang27_compat_test).

-include("../include/epgsql.hrl").

-export([run/0, test_connect/0, test_query/0, test_prepared_query/0, test_multiple_queries/0]).

%% Test module for verifying our patches for PostgreSQL 16.1 and Erlang 27.3 compatibility

%%--------------------------------------------------------------------
%% Main test function
%%--------------------------------------------------------------------
run() ->
    io:format("~n~n========== PostgreSQL 16.1 / Erlang 27.3 COMPATIBILITY TESTS ==========~n~n"),
    
    % Start with connectivity test
    ConnectionResult = test_connect(),
    
    % Only continue with query tests if connection succeeds
    case ConnectionResult of
        {ok, Conn} ->
            % Run all query tests and collect results
            QueryResult = test_query(Conn),
            PreparedResult = test_prepared_query(Conn),
            MultipleResult = test_multiple_queries(Conn),
            
            % Close connection when done
            epgsql:close(Conn),
            
            % Print summary
            io:format("~n----- TEST RESULTS SUMMARY -----~n"),
            io:format("Connection Test: ~p~n", [ok]),
            io:format("Simple Query Test: ~p~n", [QueryResult]),
            io:format("Prepared Query Test: ~p~n", [PreparedResult]),
            io:format("Multiple Queries Test: ~p~n", [MultipleResult]),
            io:format("~n========== TESTS COMPLETED ==========~n~n"),
            
            % Return overall result
            case {QueryResult, PreparedResult, MultipleResult} of
                {ok, ok, ok} -> 
                    io:format("ALL TESTS PASSED!~n"),
                    ok;
                _ -> 
                    io:format("SOME TESTS FAILED!~n"),
                    {error, {QueryResult, PreparedResult, MultipleResult}}
            end;
        Error ->
            io:format("~n----- TEST RESULTS SUMMARY -----~n"),
            io:format("Connection Test: ~p~n", [Error]),
            io:format("Other Tests: Skipped due to connection failure~n"),
            io:format("~n========== TESTS FAILED ==========~n~n"),
            Error
    end.

%%--------------------------------------------------------------------
%% Connection Test
%%--------------------------------------------------------------------
test_connect() ->
    io:format("~n----- Testing PostgreSQL 16.1 Connection -----~n"),
    
    % Connection parameters
    Host = "localhost",
    Username = "sqerl",
    Password = "sqerl",
    Database = "sqerl_test",
    
    io:format("Connecting to PostgreSQL 16.1 with parameters:~n"),
    io:format("  Host: ~s~n", [Host]),
    io:format("  Username: ~s~n", [Username]),
    io:format("  Database: ~s~n", [Database]),
    
    % Try connection with our patched epgsql
    try epgsql:connect(Host, Username, Password, [{database, Database}]) of
        {ok, _C} = Success ->
            io:format("~n✓ CONNECTION SUCCESSFUL!~n"),
            Success;
        Error ->
            io:format("~n✗ CONNECTION FAILED: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stack ->
            io:format("~n✗ CONNECTION EXCEPTION: ~p:~p~n", [Error, Reason]),
            io:format("Stack trace: ~p~n", [Stack]),
            {error, {connection_exception, {Error, Reason}}}
    end.

%%--------------------------------------------------------------------
%% Simple Query Test
%%--------------------------------------------------------------------
test_query() ->
    % Get connection first
    case test_connect() of
        {ok, C} ->
            Result = test_query(C),
            epgsql:close(C),
            Result;
        Error ->
            Error
    end.

test_query(C) ->
    io:format("~n----- Testing Simple Query -----~n"),
    
    % Simple version query
    Query = "SELECT version(), current_database()",
    io:format("Executing query: ~s~n", [Query]),
    
    try epgsql:squery(C, Query) of
        {ok, Columns, Rows} = _Success ->
            io:format("~n✓ QUERY SUCCESSFUL!~n"),
            io:format("Query returned ~p row(s)~n", [length(Rows)]),
            
            % Print result
            print_result(Columns, Rows),
            ok;
        Error ->
            io:format("~n✗ QUERY FAILED: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stack ->
            io:format("~n✗ QUERY EXCEPTION: ~p:~p~n", [Error, Reason]),
            io:format("Stack trace: ~p~n", [Stack]),
            {error, {query_exception, {Error, Reason}}}
    end.

%%--------------------------------------------------------------------
%% Prepared Query Test
%%--------------------------------------------------------------------
test_prepared_query() ->
    % Get connection first
    case test_connect() of
        {ok, C} ->
            Result = test_prepared_query(C),
            epgsql:close(C),
            Result;
        Error ->
            Error
    end.

test_prepared_query(C) ->
    io:format("~n----- Testing Prepared Query -----~n"),
    
    % Parametrized query
    Query = "SELECT $1::text AS param",
    Param = <<"PostgreSQL 16.1 and Erlang 27.3 compatibility test">>,
    io:format("Executing prepared query: ~s with parameter: ~p~n", [Query, Param]),
    
    try epgsql:equery(C, Query, [Param]) of
        {ok, Columns, Rows} = _Success ->
            io:format("~n✓ PREPARED QUERY SUCCESSFUL!~n"),
            io:format("Query returned ~p row(s)~n", [length(Rows)]),
            
            % Print result
            print_result(Columns, Rows),
            ok;
        Error ->
            io:format("~n✗ PREPARED QUERY FAILED: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stack ->
            io:format("~n✗ PREPARED QUERY EXCEPTION: ~p:~p~n", [Error, Reason]),
            io:format("Stack trace: ~p~n", [Stack]),
            {error, {prepared_query_exception, {Error, Reason}}}
    end.

%%--------------------------------------------------------------------
%% Multiple Queries Test
%%--------------------------------------------------------------------
test_multiple_queries() ->
    % Get connection first
    case test_connect() of
        {ok, C} ->
            Result = test_multiple_queries(C),
            epgsql:close(C),
            Result;
        Error ->
            Error
    end.

test_multiple_queries(C) ->
    io:format("~n----- Testing Multiple Queries -----~n"),
    
    % Multiple queries with semicolons
    Query = "SELECT 1 AS test; SELECT 2 AS test; SELECT 3 AS test;",
    io:format("Executing multiple queries: ~s~n", [Query]),
    
    try epgsql:squery(C, Query) of
        Results when is_list(Results) ->
            io:format("~n✓ MULTIPLE QUERIES SUCCESSFUL!~n"),
            io:format("Received ~p result sets~n", [length(Results)]),
            
            % Print all results
            lists:foreach(fun
                ({ok, Columns, Rows}) ->
                    io:format("~nResult set with ~p row(s):~n", [length(Rows)]),
                    print_result(Columns, Rows);
                (OtherResult) ->
                    io:format("~nOther result: ~p~n", [OtherResult])
            end, Results),
            ok;
        Error ->
            io:format("~n✗ MULTIPLE QUERIES FAILED: ~p~n", [Error]),
            Error
    catch
        Error:Reason:Stack ->
            io:format("~n✗ MULTIPLE QUERIES EXCEPTION: ~p:~p~n", [Error, Reason]),
            io:format("Stack trace: ~p~n", [Stack]),
            {error, {multiple_queries_exception, {Error, Reason}}}
    end.

%%--------------------------------------------------------------------
%% Helper Functions
%%--------------------------------------------------------------------

%% Pretty print query result
print_result(Columns, Rows) ->
    % Get column names
    Names = [binary_to_list(C#column.name) || C <- Columns],
    
    % Print header
    io:format("~n"),
    lists:foreach(fun(Name) ->
        io:format("| ~-20s ", [Name])
    end, Names),
    io:format("|~n"),
    
    % Print separator
    lists:foreach(fun(_) ->
        io:format("+-----------------------")
    end, Names),
    io:format("+~n"),
    
    % Print rows
    lists:foreach(fun(Row) ->
        Values = tuple_to_list(Row),
        lists:foreach(fun(Value) ->
            io:format("| ~-20s ", [format_value(Value)])
        end, Values),
        io:format("|~n")
    end, Rows),
    io:format("~n").

%% Format value for display
format_value(null) -> "NULL";
format_value(V) when is_binary(V) -> binary_to_list(V);
format_value(V) when is_integer(V) -> integer_to_list(V);
format_value(V) -> io_lib:format("~p", [V]).
