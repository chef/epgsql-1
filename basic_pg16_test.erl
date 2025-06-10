-module(basic_pg16_test).
-export([run/0, test_connection/0]).

% Minimal test module to verify PostgreSQL 16 connectivity using Erlang 27.3

run() ->
    compile:file(basic_pg16_test),
    test_connection().

test_connection() ->
    io:format("Testing basic connection to PostgreSQL 16 with Erlang 27.3~n"),
    
    % Connection parameters
    Host = "localhost", 
    Port = 5432,
    Database = "sqerl_test",
    User = "sqerl",
    Password = "sqerl",
    
    % Open a direct TCP socket to PostgreSQL server
    io:format("Opening TCP connection to PostgreSQL at ~s:~p~n", [Host, Port]),
    SocketResult = gen_tcp:connect(Host, Port, [binary, {packet, raw}, {active, false}]),
    
    case SocketResult of
        {ok, Socket} ->
            io:format("Successfully connected to PostgreSQL 16 at TCP level~n"),
            
            % Send a basic startup message (we're not implementing the full protocol here)
            StartupMessage = create_startup_message(User, Database),
            ok = gen_tcp:send(Socket, StartupMessage),
            
            % Receive authentication challenge (not handling the full protocol)
            receive_data(Socket),
            
            % Close the socket
            gen_tcp:close(Socket),
            {ok, "Basic connectivity test passed"};
        Error ->
            io:format("Failed to connect: ~p~n", [Error]),
            Error
    end.

% Create a minimal PostgreSQL protocol startup message
create_startup_message(User, Database) ->
    % Protocol version 3.0
    ProtocolVersion = <<3:16/integer, 0:16/integer>>,
    
    % Parameters
    UserParam = <<"user", 0, User/binary, 0>>,
    DatabaseParam = <<"database", 0, Database/binary, 0>>,
    
    % Payload (version + parameters + terminator)
    Payload = <<ProtocolVersion/binary, UserParam/binary, DatabaseParam/binary, 0>>,
    
    % Length includes itself (int32)
    Length = byte_size(Payload) + 4,
    
    % Complete message
    <<Length:32/integer, Payload/binary>>.

% Receive data from socket (simple demonstration only)
receive_data(Socket) ->
    case gen_tcp:recv(Socket, 0, 2000) of
        {ok, Data} ->
            io:format("Received ~p bytes from PostgreSQL~n", [byte_size(Data)]),
            % Display first few bytes to see response type
            case Data of
                <<Type:8/integer, _Rest/binary>> ->
                    io:format("Response message type: ~p~n", [Type]);
                _ ->
                    io:format("Unexpected response format~n")
            end;
        Error ->
            io:format("Error receiving data: ~p~n", [Error])
    end.
