-module(pg_connectivity_check).
-export([run/0, check_server/0, verify_pg_running/0]).

% Simple diagnostic tool to verify PostgreSQL connectivity

run() ->
    compile:file(pg_connectivity_check),
    verify_pg_running().

% First check if PostgreSQL is running using ps command
verify_pg_running() ->
    io:format("Starting PostgreSQL connectivity test~n"),
    io:format("Checking if PostgreSQL is running on the system...~n"),
    
    % Check direct socket connection
    Result = check_server(),
    
    case Result of
        {ok, _} ->
            io:format("PostgreSQL server appears to be running and accepting connections.~n"),
            check_auth();
        Error ->
            io:format("ERROR: PostgreSQL server does not appear to be running or is not accessible.~n"),
            io:format("Error details: ~p~n", [Error]),
            io:format("Please ensure PostgreSQL 16 is running with the following command:~n"),
            io:format("  pg_ctl -D /path/to/data/directory start~n"),
            Error
    end.

% Basic socket connection test to PostgreSQL
check_server() ->
    % Default PostgreSQL port
    Port = 5432,
    Host = "localhost",
    
    io:format("Testing TCP socket connection to ~s:~p~n", [Host, Port]),
    
    % Try a simple socket connection
    case gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}], 5000) of
        {ok, Socket} ->
            io:format("Successfully opened TCP connection to PostgreSQL!~n"),
            gen_tcp:close(Socket),
            {ok, connected};
        Error ->
            Error
    end.

% Check authentication with the target user
check_auth() ->
    io:format("Checking PostgreSQL credentials...~n"),
    Username = "sqerl",
    Password = "sqerl",
    Database = "sqerl_test",
    
    io:format("Attempting connection with:~n"),
    io:format("Username: ~p~n", [Username]),
    io:format("Database: ~p~n", [Database]),
    
    % Build a simple startup message to test auth
    Message = build_startup_message(Username, Database, Password),
    
    send_pg_startup(Message).

% Build a simple PostgreSQL protocol startup message
build_startup_message(Username, Database, _Password) ->
    % Protocol version 3.0
    ProtocolVersion = <<3:16/integer, 0:16/integer>>,
    
    % Parameters as null-terminated strings
    UserParam = list_to_binary(["user", 0, Username, 0]),
    DatabaseParam = list_to_binary(["database", 0, Database, 0]),
    
    % Complete message including terminator
    Payload = <<ProtocolVersion/binary, UserParam/binary, DatabaseParam/binary, 0>>,
    
    % Length includes itself (int32)
    Length = byte_size(Payload) + 4,
    
    % Final message with length header
    <<Length:32/integer, Payload/binary>>.

% Send startup message to PostgreSQL and analyze response
send_pg_startup(Message) ->
    Host = "localhost",
    Port = 5432,
    
    case gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}], 5000) of
        {ok, Socket} ->
            % Send startup message
            io:format("Sending startup message to PostgreSQL...~n"),
            ok = gen_tcp:send(Socket, Message),
            
            % Get response
            case gen_tcp:recv(Socket, 0, 5000) of
                {ok, Data} ->
                    io:format("Received ~p bytes from PostgreSQL~n", [byte_size(Data)]),
                    % Analyze the first byte (message type)
                    case Data of
                        <<82, _Rest/binary>> ->
                            % Authentication request ('R')
                            io:format("PostgreSQL requested authentication (good sign)~n"),
                            {ok, auth_requested};
                        <<69, _Rest/binary>> ->
                            % Error message ('E')
                            io:format("PostgreSQL returned an error~n"),
                            {error, postgres_error};
                        _ ->
                            io:format("Unexpected response type: ~p~n", [Data]),
                            {error, unexpected_response}
                    end;
                Error ->
                    io:format("Error receiving response: ~p~n", [Error]),
                    Error
            end;
        Error ->
            io:format("Connection error: ~p~n", [Error]),
            Error
    end.
