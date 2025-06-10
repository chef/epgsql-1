-module(basic_connect).
-export([test/0]).

% Start epgsql application and attempt the connection with minimal options
test() ->
    % Make sure OTP applications are started
    application:ensure_all_started(epgsql),
    
    % Create the connection process
    {ok, Conn} = epgsql:start_link(),
    
    % Set up connection parameters with minimal options
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
    
    % Try the connection, using try/catch to handle any errors
    Result = try
        ConnResult = epgsql:connect(Conn, Host, Username, Password, Options),
        io:format("Connection result: ~p~n", [ConnResult]),
        
        % If connected, run a simple query
        case ConnResult of
            {ok, _} ->
                {ok, Columns, Rows} = epgsql:squery(Conn, "SELECT version()"),
                io:format("Query columns: ~p~n", [Columns]),
                io:format("PostgreSQL version: ~p~n", [Rows]),
                ok;
            _ -> 
                ConnResult
        end
    catch
        ErrorType:ErrorReason:Stacktrace ->
            io:format("Connection error: ~p:~p~n", [ErrorType, ErrorReason]),
            io:format("Stack trace: ~p~n", [Stacktrace]),
            {error, ErrorReason}
    after
        % Always attempt to close the connection
        catch epgsql:close(Conn)
    end,
    
    Result.
