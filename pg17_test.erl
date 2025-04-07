-module(pg17_test).
-export([connect/0, test_query/0]).

connect() ->
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "postgres",
        password => "postgres",
        database => "postgres",
        port => 5433,  % Note: Using port 5433 as we mapped the container's 5432 to host's 5433
        timeout => 4000
    }),
    {ok, C}.

test_query() ->
    {ok, C} = connect(),
    Result = epgsql:squery(C, "SELECT version()"),
    io:format("PostgreSQL version: ~p~n", [Result]),
    epgsql:close(C),
    Result.
