-module(pg16_oldstyle).
-export([connect/0, test_query/0]).

connect() ->
    % Use older style connection options with separate parameters
    % instead of the map style that's causing issues with Erlang 27.3
    Host = "localhost",
    Username = "sqerl",
    Password = "sqerl",
    Options = [{database, "sqerl_test"}, {port, 5432}],
    {ok, C} = epgsql:connect(Host, Username, Password, Options),
    {ok, C}.

test_query() ->
    {ok, C} = connect(),
    Result = epgsql:squery(C, "SELECT version()"),
    io:format("PostgreSQL version: ~p~n", [Result]),
    epgsql:close(C),
    Result.
