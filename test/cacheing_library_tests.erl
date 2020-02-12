%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Feb 2020 13:37
%%%-------------------------------------------------------------------
-module(cacheing_library_tests).
-author("erlang").
-include("header.hrl").
-include_lib("eunit/include/eunit.hrl").

start_test()->
%%  gen_server:start()
  my_cache:start_link().

insert_test()->
  my_cache:start_link(),
  ?assertEqual(ok,my_cache:insert("TestKey1","TestValue1",0)).

second_test()->
  my_cache:start_link(),
  my_cache:insert("TestKey1","TestValue1",-1),
  ?assertEqual({my_cache_state,"cache_dets.file",{ok,[]}},my_cache:lookup("TestKey1")).

third_test()->
  my_cache:start_link(),
  my_cache:insert("TestKey1","TestValue1",-1),
  my_cache:delete_obsolete(?STANDARD),
  ?assertEqual({my_cache_state,"cache_dets.file",{ok,[]}},my_cache:lookup("TestKey1")).

fourth_test()->
  my_cache:start_link(),
  my_cache:insert("TestKey1","TestValue1",-1),
  my_cache:delete_obsolete(?NONSTANDARD),
  ?assertEqual({my_cache_state,"cache_dets.file",{ok,[]}},my_cache:lookup("TestKey1")).

end_test()->
  gen_server:stop(my_cache).