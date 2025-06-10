-module(pg16_test).
-export([connect/0, test_query/0]).

connect() ->
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "sqerl",
        password => "sqerl",
        database => "sqerl_test",  % The database that was created by the POSTGRES_DB env var
        port => 5432,  % PostgreSQL 16.1 is on the default port 5432
        timeout => 4000
    }),
    {ok, C}.

test_query() ->
    {ok, C} = connect(),
    Result = epgsql:squery(C, "SELECT version()"),
    io:format("PostgreSQL version: ~p~n", [Result]),
    epgsql:close(C),
    Result.
