-module(pg16_erlang27_auth).
-export([connect/0, test_query/0, run/0]).

% Connect using binary password to avoid authentication issues
connect() ->
    % Start the connection process
    {ok, C} = epgsql_sock:start_link(),
    
    % Create connection map with more explicit options and binary password
    Opts = #{
        host => "localhost",
        username => "postgres",  % Try the default PostgreSQL user
        password => <<"postgres">>,  % Password as binary to avoid encoding issues
        database => "postgres",  % Default database
        port => 5432,
        timeout => 5000
    },
    
    % Use the epgsql:connect function
    case epgsql:connect(C, maps:get(host, Opts), 
                          maps:get(username, Opts),
                          maps:get(password, Opts),
                          [{database, maps:get(database, Opts)}, 
                           {port, maps:get(port, Opts)},
                           {timeout, maps:get(timeout, Opts)}]) of
        {ok, Connection} -> 
            io:format("Connected successfully!~n"),
            {ok, Connection};
        Error -> 
            io:format("Connection error: ~p~n", [Error]),
            Error
    end.

test_query() ->
    case connect() of
        {ok, C} ->
            io:format("Connected to PostgreSQL 16~n"),
            Result = epgsql:squery(C, "SELECT version()"),
            io:format("PostgreSQL version: ~p~n", [Result]),
            epgsql:close(C),
            {ok, Result};
        Error ->
            Error
    end.

% Helper function to run test 
run() ->
    compile:file(pg16_erlang27_auth),
    test_query().
