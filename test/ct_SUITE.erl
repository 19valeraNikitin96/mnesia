%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Feb 2020 15:38
%%%-------------------------------------------------------------------
-module(ct_SUITE).

-author("erlang").

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-include("cache_data_mnesia.hrl").
-include("header.hrl").

-compile(export_all).

all() ->
  [
    {group,g_cacheing_library},
    {group,g_mnesia},
    {group,g_web_server}
  ].

groups()->[
  {g_cacheing_library,
    [],
    [insert_test,lookup_test1,lookup_test2]},
  {g_mnesia,
    [],
    [insert_m_test,read_test1,delete_test,read_test2]},
  {g_web_server,
    [],
    [web_server_test1,web_server_test2,web_server_test3]}
].

init_per_suite(Config) ->
  application:ensure_all_started(mnesia_cache),
  Config.

init_per_group(g_cacheing_library, Config)->
  my_cache:insert("CT_Key_Test1", "CT_Value_Test1", 60),
  my_cache:insert("CT_Key_Test2", 60, 60),
  my_cache:insert(60, "CT_Value_Test2", 60),
  Config;
init_per_group(g_mnesia, Config)->
  Row = #cache_data{key = "MnesiaTestKey1",value = "MnesiaTestValue1",end_time = erlang:system_time('second')+3600},
  F = fun()->mnesia:write(Row) end,
  mnesia:transaction(F),
  Config;
init_per_group(g_web_server, Config)->
  inets:start(),
  Config.

end_per_group(g_cacheing_library, _Config)->
  my_cache:delete_obsolete(?STANDARD);
end_per_group(g_mnesia, _Config)->
  F = fun()->mnesia:delete({cache_data, "MnesiaTestKey1"}) end,
  mnesia:transaction(F);
end_per_group(g_web_server, _Config)->
  inets:stop().

end_per_suite(Config) ->
  application:stop(mnesia_cache),
  mnesia:stop(),
  Config.
%%===========================================================================
%%CACHEING LIBRARY GROUP

insert_test(_Config)->
  Res = my_cache:insert("CT_Key_Test1", "CT_Value_Test1", 60),
  ?assertEqual('ok',Res).

lookup_test1(_Config)->
  {_State,_Dets,{Status, Res}} = my_cache:lookup("TestKey1"),
  ?assertEqual('ok',Status),
  ?assertEqual([],Res).

lookup_test2(_Config)->
  {_State,_Dets,{Status, [{K,V,_E}]}} = my_cache:lookup("CT_Key_Test1"),
  ?assertEqual('ok',Status),
  ?assertEqual("CT_Key_Test1",K),
  ?assertEqual("CT_Value_Test1",V).

%%===========================================================================
%%MNESIA GROUP

insert_m_test(_Config)->
  Row = #cache_data{key = "MnesiaTestKey2",value = "MnesiaTestValue2",end_time = erlang:system_time('second')+3600},
%%  Row = {cache_data,"MnesiaTestKey2","MnesiaTestValue2",erlang:system_time('second')+3600},
  F = fun()->mnesia:write(Row) end,
  Res = mnesia:transaction(F),
  ?assertEqual({'atomic', ok}, Res).

read_test1(_Config)->
  F = fun()->mnesia:read(cache_data, "MnesiaTestKey2") end,
  {'atomic',[{cache_data,"MnesiaTestKey2",Value,_EndTime}]} = mnesia:transaction(F),
  ?assertEqual("MnesiaTestValue2", Value).

delete_test(_Config)->
  F = fun()->mnesia:delete({cache_data, "MnesiaTestKey2"}) end,
  Res = mnesia:transaction(F),
  ?assertEqual({'atomic','ok'},Res).

read_test2(_Config)->
  F = fun()->mnesia:read(cache_data, "MnesiaTestKey2") end,
  {'atomic',List} = mnesia:transaction(F),
  ?assertEqual([], List).

%%===========================================================================
%%WEB SERVER

web_server_test1(_Config) ->
  Body = "{
    \"action\": \"insert\",
    \"key\": 11349,
    \"value\": 1149
  }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":\"ok\"}", RBody).

web_server_test2(_Config)->
  Body = "{
    \"action\": \"lookup\",
    \"key\": 11349
    }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":1149}", RBody).

web_server_test3(_Config)->
  Body2 = "{
    \"action\": \"lookup\",
    \"key\": \"abrakadabra\"
    }",
  R = httpc:request(post,{"http://localhost:8080/api/cache_server", [],"application/json",Body2},[],[]),
  {ok, {{"HTTP/1.1", ReturnCode, _State}, _Head, RBody}} = R,
  ?assertEqual(200, ReturnCode),
  ?assertEqual("{\"result\":\"undefined\"}", RBody).


