%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Feb 2020 11:38
%%%-------------------------------------------------------------------
-module(mnesia_tests).
-author("erlang").
-include("cache_data_mnesia.hrl").
-include_lib("eunit/include/eunit.hrl").

init_scheme_test() ->
  mnesia:create_schema([node()]).

start_scheme_test()->
  mnesia:start().

init_table_cache_test()->
  mnesia:create_table(cache_data, [{attributes,record_info(fields,cache_data)}]).

insert_test()->
  Row = #cache_data{key = "MnesiaTestKey",value = "MnesiaTestValue",end_time = erlang:system_time('second')+3600},
  F = fun()->mnesia:write(Row) end,
  Res = mnesia:transaction(F),
  ?assertEqual({'atomic', ok}, Res).

read_test()->
  F = fun()->mnesia:read(cache_data, "MnesiaTestKey") end,
  {'atomic',[{cache_data,"MnesiaTestKey",Value,_EndTime}]} = mnesia:transaction(F),
  ?assertEqual("MnesiaTestValue", Value).

delete_test()->
  F = fun()->mnesia:delete({cache_data, "MnesiaTestKey"}) end,
  Res = mnesia:transaction(F),
  ?assertEqual({'atomic','ok'},Res).

%%TABLE EVENTS

first_event_test()->
  [Node|[]] = mnesia_lib:all_nodes(),
  {'ok', Node} = mnesia:subscribe({'table', cache_data, 'detailed'}),
  Row = #cache_data{key = "MnesiaTestKey",value = "MnesiaTestValue",end_time = erlang:system_time('second')+3600},
  F = fun()->mnesia:write(Row) end,
  mnesia:transaction(F),
  F2 = fun()->mnesia:delete({cache_data, "MnesiaTestKey"}) end,
  mnesia:transaction(F2),
  mnesia:report_event({'table', cache_data, 'detailed'}),
  mnesia_subscr:subscribers(),
  {messages, EventsList} = erlang:process_info(self(), messages),
  mnesia:unsubscribe({'table', cache_data, 'detailed'}),
  ?assertEqual(2, length(EventsList)).

end_scheme_test()->
  mnesia:stop().