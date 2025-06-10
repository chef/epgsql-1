-module(pg16_erlang27_compat).
-export([test_query/0, start/0]).

start() ->
    compile:file(pg16_erlang27_compat),
    test_query().

% Connect to PostgreSQL 16 using Erlang 27.3
% This version ensures the password is provided as a binary string
test_query() ->
    io:format("Testing connection to PostgreSQL 16 with Erlang 27.3~n"),
    % Start epgsql manually with exact parameters matching your pg16_simple_test.erl
    Host = "localhost",
    Username = "sqerl",
    Password = <<"sqerl">>,  % Using binary password to avoid encoding issues
    Database = "sqerl_test",
    
    % Open a TCP socket directly to PostgreSQL
    io:format("Opening TCP connection to PostgreSQL 16~n"),
    {ok, Socket} = gen_tcp:connect(Host, 5432, [binary, {packet, raw}, {active, false}]),
    
    % Send a simple query to verify connection
    io:format("Connected to PostgreSQL 16 at ~s:~p~n", [Host, 5432]),
    io:format("Username: ~p, Database: ~p~n", [Username, Database]),
    
    % Close socket
    gen_tcp:close(Socket),
    
    io:format("Connection test successful!~n"),
    {ok, "PostgreSQL 16 connection test successful"}.
