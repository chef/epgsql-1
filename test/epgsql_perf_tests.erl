%%%

-module(epgsql_perf_tests).

-include_lib("eunit/include/eunit.hrl").

%%

perf_test_() ->
    [
        {timeout, 60, prepare_data()},
        {timeout, 60, get_data()}
    ].

drop_data_test_() ->
    drop_data().

%%

-define(noise_size, 10000000).

prepare_data() ->
    {"insert blob", with_connection(fun (C) ->
        Noise = noise(?noise_size),
        {ok, [], []} = epgsql:squery(C, "create table test_big_blobs (id int4 primary key, noise bytea)"),
        {ok, 1} = epgsql:equery(C, "insert into test_big_blobs (id, noise) values (1, $1)", [Noise])
    end)}.

get_data() ->
    {"get blob back", with_connection(fun (C) ->
        {ok, _, [{Noise}]} = epgsql:equery(C, "select noise from test_big_blobs"),
        ?assertEqual(?noise_size, byte_size(Noise))
    end)}.

drop_data() ->
    {"cleanup", with_connection(fun (C) ->
        {ok, [], []} = epgsql:squery(C, "drop table test_big_blobs")
    end)}.

noise(N) ->
    crypto:strong_rand_bytes(N).

%%

-define(host, "localhost").
-define(port, 10432).

with_connection(F) ->
    with_connection(F, "epgsql_test", []).

with_connection(F, Username, Args) ->
    Args2 = [{port, ?port}, {database, "epgsql_test_db1"} | Args],
    fun () ->
        {ok, C} = epgsql:connect(?host, Username, Args2),
        try
            F(C)
        after
            epgsql:close(C)
        end
    end.
