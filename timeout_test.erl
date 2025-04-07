-module(timeout_test).
-export([test_normal/0, test_timeout/0, test_long_query/0, run_all/0]).

% Run all tests
run_all() ->
    try
        io:format("~n=== Running normal connection test ===~n"),
        test_normal(),
        
        io:format("~n=== Running timeout test (expected to timeout) ===~n"),
        test_timeout(),
        
        io:format("~n=== Running long query test (should succeed) ===~n"),
        test_long_query()
    catch
        E:R:S -> 
            io:format("Error: ~p:~p~n", [E, R]),
            io:format("Stack: ~p~n", [S])
    end.

% Normal connection with default timeout (infinity)
test_normal() ->
    io:format("Testing normal connection with default timeout (infinity)~n"),
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "postgres",
        password => "postgres",
        database => "postgres",
        port => 5433
    }),
    Result = epgsql:squery(C, "SELECT version()"),
    io:format("PostgreSQL version: ~p~n", [Result]),
    epgsql:close(C),
    Result.

% Connection with a short req_timeout 
test_timeout() ->
    io:format("Testing connection with a short req_timeout (500 milliseconds)~n"),
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "postgres",
        password => "postgres",
        database => "postgres",
        port => 5433,
        req_timeout => 500  % 500 milliseconds timeout
    }),
    
    % Test with a query that will take longer than the timeout
    io:format("Executing a query that will take longer than the timeout...~n"),
    try
        Result = epgsql:squery(C, "SELECT pg_sleep(5)"),
        io:format("Result: ~p~n", [Result]),
        epgsql:close(C),
        Result
    catch
        exit:{timeout, _} -> 
            io:format("Successfully detected timeout as expected!~n"),
            {error, timeout};
        E:R -> 
            io:format("Unexpected error: ~p:~p~n", [E, R]),
            {error, R}
    end.

% Test with a long-running query and sufficient timeout
test_long_query() ->
    io:format("Testing long-running query with sufficient timeout~n"),
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "postgres",
        password => "postgres",
        database => "postgres",
        port => 5433,
        req_timeout => 10000  % 10 seconds timeout
    }),
    
    % Test with a query that will complete within the timeout
    io:format("Executing a query that will complete within the timeout...~n"),
    Result = epgsql:squery(C, "SELECT pg_sleep(2)"),
    io:format("Result: ~p~n", [Result]),
    epgsql:close(C),
    Result.
