-module(pg16_simple_test).
-export([connect/0, test_query/0]).

connect() ->
    % Explicitly set socket_active to true to avoid the case_clause error
    {ok, C} = epgsql:connect(#{
        host => "localhost",
        username => "sqerl",
        password => "sqerl",
        database => "sqerl_test",  % The database created by POSTGRES_DB env var
        port => 5432,  % PostgreSQL 16.1 port
        timeout => 4000,
        socket_active => true  % Explicitly set socket_active to true
    }),
    {ok, C}.

test_query() ->
    {ok, C} = connect(),
    Result = epgsql:squery(C, "SELECT version()"),
    io:format("PostgreSQL version: ~p~n", [Result]),
    epgsql:close(C),
    Result.
