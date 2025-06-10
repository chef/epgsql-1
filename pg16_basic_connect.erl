-module(pg16_basic_connect).
-export([run/0, test_connection/0, test_epgsql_connect/0]).

% Simple test module to verify PostgreSQL 16 connectivity with Erlang 27.3

run() ->
    compile:file(pg16_basic_connect),
    test_connection().

% Basic TCP connection test to PostgreSQL 16
test_connection() ->
    io:format("Testing basic TCP connection to PostgreSQL 16 with Erlang 27.3~n"),
    
    % Connection parameters
    Host = "localhost", 
    Port = 5432,
    
    % Open a direct TCP socket to PostgreSQL server
    io:format("Opening TCP connection to PostgreSQL at ~s:~p~n", [Host, Port]),
    SocketResult = gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}]),
    
    case SocketResult of
        {ok, Socket} ->
            io:format("Successfully connected to PostgreSQL 16 at TCP level~n"),
            
            % We won't attempt to implement the full PostgreSQL protocol here
            % Just verifying that the server accepts our connection
            
            % Close the socket
            gen_tcp:close(Socket),
            io:format("TCP connection test successful~n"),
            {ok, "Basic connectivity test passed"};
        Error ->
            io:format("Failed to connect: ~p~n", [Error]),
            Error
    end.

% Attempt to connect via the epgsql library with custom error handling for Erlang 27.3
test_epgsql_connect() ->
    io:format("Testing epgsql connection to PostgreSQL 16 with Erlang 27.3~n"),
    
    % Start the epgsql application if it's not already started
    application:start(epgsql),
    
    % Standard connection parameters 
    Host = "localhost", 
    Username = "sqerl",
    Password = "sqerl",
    Database = "sqerl_test",
    Port = 5432,
    
    % Use a try-catch block to handle all possible errors
    try
        % Start the connection process
        {ok, C} = epgsql_sock:start_link(),
        
        % Create connection options
        Opts = #{host => Host,
                username => Username,
                password => Password,
                database => Database,
                port => Port,
                timeout => 5000},
        
        % Attempt connection with error pattern matching
        connect_with_erlang27_handling(C, Opts)
    catch
        error:Error:Stacktrace ->
            io:format("Error during connection: ~p~nStacktrace: ~p~n", [Error, Stacktrace]),
            {error, {Error, Stacktrace}};
        throw:Error ->
            io:format("Throw during connection: ~p~n", [Error]),
            {error, Error};
        exit:Error ->
            io:format("Exit during connection: ~p~n", [Error]),
            {error, Error}
    end.

% Helper function for connection with special Erlang 27.3 handling
connect_with_erlang27_handling(C, Opts) ->
    % Attempt direct gen_server call to bypass the problematic connect function
    Result = gen_server:call(C, {command, epgsql_cmd_connect, Opts}, infinity),
    
    case Result of
        {active, Pid} when is_pid(Pid) ->
            io:format("Received {active, Pid} result, waiting for actual connection message~n"),
            % Handle Erlang 27.3 case explicitly
            receive
                {epgsql, Pid, connected} ->
                    io:format("Successfully connected to PostgreSQL 16~n"),
                    % Try a simple query to verify connection works
                    try_query(C);
                {epgsql, Pid, Error} ->
                    io:format("Connection error: ~p~n", [Error]),
                    {error, Error}
            after 5000 ->
                io:format("Connection timed out waiting for response~n"),
                {error, timeout}
            end;
        connected ->
            io:format("Connected to PostgreSQL 16 successfully~n"),
            try_query(C);
        Error ->
            io:format("Connection error: ~p~n", [Error]),
            {error, Error}
    end.

% Try a simple query on the connection
try_query(C) ->
    % Use direct gen_server call again to bypass potential issues
    QueryResult = gen_server:call(C, {command, epgsql_cmd_squery, "SELECT version()"}, infinity),
    
    case QueryResult of
        {ok, Columns, Rows} ->
            io:format("Query successful: ~p~n", [Rows]),
            % Close connection
            epgsql_sock:close(C),
            {ok, Rows};
        {active, Pid} when is_pid(Pid) ->
            % Handle Erlang 27.3 case for query result
            receive
                {epgsql, Pid, {ok, Columns, Rows}} ->
                    io:format("Query successful: ~p~n", [Rows]),
                    epgsql_sock:close(C),
                    {ok, Rows};
                {epgsql, Pid, Error} ->
                    io:format("Query error: ~p~n", [Error]),
                    epgsql_sock:close(C),
                    {error, Error}
            after 5000 ->
                io:format("Query timed out~n"),
                epgsql_sock:close(C),
                {error, timeout}
            end;
        Error ->
            io:format("Query error: ~p~n", [Error]),
            epgsql_sock:close(C),
            {error, Error}
    end.
