-module(pg16_async).
-export([test/0]).

% Use the asynchronous API of epgsql (epgsqla)
test() ->
    % Make sure OTP applications are started
    application:ensure_all_started(epgsql),
    
    % Create the connection process using epgsqla
    {ok, C} = epgsqla:start_link(),
    
    % Set up connection parameters
    Host = "localhost",
    Username = "sqerl",
    Password = "sqerl",
    Options = [{database, "sqerl_test"}, {port, 5432}],
    
    % Print connection details
    io:format("Connecting to PostgreSQL with:~n"),
    io:format("Host: ~p~n", [Host]),
    io:format("Username: ~p~n", [Username]),
    io:format("Database: sqerl_test~n"),
    io:format("Port: 5432~n"),
    
    % Try the connection
    Ref = epgsqla:connect(C, Host, Username, Password, Options),
    
    % Wait for connection result
    receive
        {C, Ref, connected} ->
            io:format("Connected successfully!~n"),
            
            % Run a simple query
            QueryRef = epgsqla:squery(C, "SELECT version();"),
            
            % Wait for query result
            receive
                {C, QueryRef, {ok, Columns, Rows}} ->
                    io:format("Query successful!~n"),
                    io:format("Columns: ~p~n", [Columns]),
                    io:format("PostgreSQL version: ~p~n", [Rows]),
                    ok;
                {C, QueryRef, Error} ->
                    io:format("Query error: ~p~n", [Error]),
                    Error
            after 5000 ->
                io:format("Query timeout~n"),
                {error, query_timeout}
            end,
            
            % Close the connection
            epgsql:close(C);
            
        {C, Ref, Error} ->
            io:format("Connection error: ~p~n", [Error]),
            Error
    after 5000 ->
        io:format("Connection timeout~n"),
        {error, timeout}
    end.
