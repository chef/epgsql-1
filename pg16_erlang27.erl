-module(pg16_erlang27).
-export([connect/0, test_query/0]).

% Connect function with modifications for Erlang 27.3
connect() ->
    % Start connection process explicitly
    {ok, C} = epgsql_sock:start_link(),
    
    % Using older connection style with explicit parameters
    Host = "localhost",
    Username = "sqerl",  % From your existing pg16_oldstyle.erl
    Password = "sqerl",  % From your existing pg16_oldstyle.erl
    
    % Options with explicit TCP socket settings for Erlang 27.3
    Options = [
        {database, "sqerl_test"},  % From your existing pg16_oldstyle.erl
        {port, 5432},
        {timeout, 5000},
        % Don't use socket_active to avoid the case_clause error with Erlang 27.3
        {tcp_opts, [{active, true}, {packet, raw}]}
    ],
    
    % Connect using raw parameters
    epgsql:connect(C, Host, Username, Password, Options).

test_query() ->
    case connect() of
        {ok, C} ->
            io:format("Successfully connected to PostgreSQL 16~n"),
            Result = epgsql:squery(C, "SELECT version()"),
            io:format("PostgreSQL version: ~p~n", [Result]),
            epgsql:close(C),
            {ok, Result};
        Error ->
            io:format("Connection error: ~p~n", [Error]),
            Error
    end.
