%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Feb 2020 13:38
%%%-------------------------------------------------------------------
-module(web_server_tests).
-author("erlang").

-include_lib("eunit/include/eunit.hrl").

start_test()->
  application:ensure_all_started(mnesia_cache),
  inets:start().

first_test() ->
  Body = "{
    \"action\": \"insert\",
    \"key\": 11349,
    \"value\": 1149
  }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":\"ok\"}", RBody).

second_test()->
  Body = "{
    \"action\": \"lookup\",
    \"key\": 11349
    }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":1149}", RBody).

third_test()->
  Body2 = "{
    \"action\": \"lookup\",
    \"key\": \"abrakadabra\"
    }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body2},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":\"undefined\"}", RBody).

end_test()->
  application:stop(my_cache),
  inets:stop().