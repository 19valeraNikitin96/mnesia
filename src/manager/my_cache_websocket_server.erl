%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Feb 2020 17:31
%%%-------------------------------------------------------------------
-module(my_cache_websocket_server).
-author("erlang").

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).

init(Req, Opts) ->
  {cowboy_websocket, Req, Opts,#{idle_timeout=>30000}}.

websocket_init(State) ->
  io:format("~w~w~n", [websocket_pid,self()]),
  mnesia_observer:subscribe(self()),
  mnesia:subscribe({'table', cache_data, 'detailed'}),
  erlang:start_timer(1000, self(), <<"Hello!">>),
  {[], State}.

websocket_handle({text, Msg}, State) ->
  case Msg  of
%%    <<"flush">> -> io:format("~w~n",[erlang:process_info(self(), messages)]),{[{text, << "That's what she said! ",Msg/binary >>}], State};
    _ -> {[{text, << "That's what she said! ",Msg/binary >>}], State}
  end;
websocket_handle(_Data, State) ->
  {[], State}.
websocket_info({timeout, _Ref,{mnesia_event,Msg}},State) ->
  io:format("~w~w~n",[mnesia_event,Msg]),
  {[{text, Msg}],State};
websocket_info({timeout,_Ref,Msg},State) ->
  io:format("~w~n",[Msg]),
  {[{text, Msg}],State};
websocket_info(_Info, State) ->
  {[], State}.