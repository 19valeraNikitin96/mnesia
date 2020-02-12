%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Feb 2020 13:36
%%%-------------------------------------------------------------------
-module(my_cache_impl).
-author("erlang").
-include("header.hrl").
%% API
-export([insert/2, lookup/2, delete_obsolete/2, lookup/3, date_to_seconds/1]).

insert(Dets_ID, {Key,Value,TimeEnd})->
  dets:insert(Dets_ID,{Key,Value,TimeEnd}).

lookup(Dets_ID, Key)->
  clear_standard(Dets_ID),
  {ok,dets:lookup(Dets_ID, Key)}.

lookup(DateFrom,DateTo,Dets_ID)->
  [FDate, FTime] = string:split(DateFrom, " ", all),
  [TDate, TTime] = string:split(DateTo, " ", all),
  [FYear,FMonth,FDay,TYear,TMonth,TDay,FHours,FMinutes,FSeconds,THours,TMinutes,TSeconds] =
    lists:flatmap(
      fun(X) -> [list_to_integer(binary_to_list(X))] end,
      lists:flatmap(fun(X) -> string:split(X, "/", all) end, [FDate, TDate])
      ++
      lists:flatmap(fun(X) -> string:split(X, ":", all) end, [FTime, TTime])
    ),
  FS =
    calendar:datetime_to_gregorian_seconds({{FYear-1970, (FMonth), (FDay)},{(FHours), (FMinutes), (FSeconds)}}),
  TS =
    calendar:datetime_to_gregorian_seconds({{TYear-1970, (TMonth), (TDay)},{(THours), (TMinutes), (TSeconds)}}),
  Ret = lists:filter(fun(X) -> {_,_,EndDate} = X, EndDate >= FS andalso EndDate =< TS end,
  all_records_from(Dets_ID)),lists:flatmap(fun(X)->{_,V,_}=X, [V] end, Ret).

%% MINOR FUNCTIONS

all_records_from(Dets_ID) ->
  Temp_Ets_ID = ets:new(temp_ets, []),
  dets:to_ets(Dets_ID, Temp_Ets_ID),
  Result = ets:tab2list(Temp_Ets_ID),
  ets:delete(Temp_Ets_ID),
  Result.

delete_obsolete(Method,Dets_ID)->
  case Method of
    ?STANDARD -> clear_standard(Dets_ID);
    ?NONSTANDARD -> clear_nonstandard(Dets_ID)
  end.

clear_standard(Dets_ID)->
  ?STANDARD(all_records_from(Dets_ID), Dets_ID).
clear_standard([], _Dets_ID)-> ok;
clear_standard([{_,_,EndTime}=H|T], Dets_ID) ->
  case erlang:system_time(?SEC) > EndTime of
    true -> dets:delete_object(Dets_ID, H), ?STANDARD(T, Dets_ID);
    false -> ?STANDARD(T, Dets_ID)
  end.

clear_nonstandard(Dets_ID)->
  clear_nonstandard(dets:first(Dets_ID),Dets_ID).
clear_nonstandard('$end_of_table',_Dets_ID)->ok;
clear_nonstandard(Key,Dets_ID) ->
  [{Key,_Value,EndTime}] = dets:lookup(Dets_ID,Key),
  case EndTime < erlang:system_time(?SEC) of
    true -> Next = dets:next(Dets_ID,Key),dets:delete(Dets_ID, Key),clear_nonstandard(Next, Dets_ID);
    false -> clear_nonstandard(dets:next(Dets_ID,Key), Dets_ID)
  end.

date_to_seconds(Date0)->
%%  io:format("~w~n", [string:split(binary_to_list(Date), " ", all)]),
  [Date, Time] = string:split(Date0, " ", all),
  [Year,Month,Day,Hours,Minutes,Seconds] =
    lists:flatmap(
      fun(X) -> [list_to_integer(binary_to_list(X))] end,
      lists:flatmap(fun(X) -> string:split(X, "/", all) end, [Date])
      ++
      lists:flatmap(fun(X) -> string:split(X, ":", all) end, [Time])
    ),
  calendar:datetime_to_gregorian_seconds({{Year-1970, (Month), (Day)},{(Hours), (Minutes), (Seconds)}}).