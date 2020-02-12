%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Feb 2020 11:36
%%%-------------------------------------------------------------------
-module(my_cache_mnesia_manager).
-author("erlang").
-include("cache_data_mnesia.hrl").
-include("header.hrl").
-include_lib("stdlib/include/qlc.hrl").
-behaviour(gen_server).
%% API
-export([init/1, handle_call/3, handle_cast/2, start_link/0]).
-export([lookup/1, lookup/2, delete_obsolete/1, insert/1]).

-record(cache_data_state, {}).

start_link() ->
  gen_server:start_link({local,?MODULE},?MODULE,[],[]).

init(_Args) ->
  {ok,#cache_data_state{}}.

handle_call({?INSERT, #cache_data{key = _Key,value = _Value,end_time = _EndTime}=R}, _From, State) ->
  F = fun()->mnesia:write(R) end,
  mnesia:transaction(F),
  {reply,'ok',State};
handle_call({?LOOKUP, Key}, _From, State) ->
  F = fun()->mnesia:read(?TABLE, Key) end,
  Res = mnesia:transaction(F),
  {reply,Res,State};
handle_call({?LOOKUP, DateFrom, DateTo}, _From, State) ->
  FS = my_cache_impl:date_to_seconds(DateFrom),
  TS = my_cache_impl:date_to_seconds(DateTo),
  F = fun()->qlc:eval(qlc:q([X#cache_data.value || X <- mnesia:table(?TABLE), X#cache_data.end_time >= FS, X#cache_data.end_time =< TS])) end,
  Res = mnesia:transaction(F),
  io:format("~w~n",[Res]),
  {reply,Res,State}.

handle_cast(_Request, State) ->
  {reply, ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

insert(Record)->
  gen_server:call(?MODULE, {?INSERT, Record}).

lookup(Key)->
  gen_server:call(?MODULE, {?LOOKUP, Key}).

lookup(DateFrom, DateTo)->
  gen_server:call(?MODULE, {?LOOKUP, DateFrom, DateTo}).

delete_obsolete(Method)->
  gen_server:cast(?MODULE, {?DELETE, Method}).

%%%===================================================================
