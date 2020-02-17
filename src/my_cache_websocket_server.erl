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
%%  io:format("~w~w~n", [initSoc,Req]),
  {cowboy_websocket, Req, Opts,#{idle_timeout=>30000}}.

%%is_authorized(Req0)->
%%  Token = cowboy_req:header(<<"Authorization">>, Req0),
%%  case Token of
%%    undefined -> failed;
%%    _ -> {Status, _Decoded } = jwt:decode(Token, <<"secret">>),
%%      case Status == ok of
%%        true ->  ok;
%%        false -> cowboy_req:reply(400, Req0), failed
%%      end
%%  end.

%%is_authorized(Req0)->
%%  Headers = cowboy_req:headers(Req0),
%%  QsVals = cowboy_req:parse_qs(Req0),
%%  case lists:keyfind(<<"token">>, 1, QsVals) of
%%    false -> failed;
%%    {_, Token} -> {Status, _Decoded } = jwt:decode(Token, <<"secret">>),
%%      case Status == ok of
%%        true ->  ok;
%%        false -> cowboy_req:reply(400, Req0), failed
%%      end
%%  end.



%%is_authorized(Req,State) ->
%%  {Type, User, Pass} = cowboy_req:parse_header(<<"Authorization">>, Req),
%%  io:format("~w~w~n",[auth_type,Type]),
%%  io:format("~w~w~n",[user,User]),
%%  io:format("~w~w~n",[pass,Pass]),
%%%%  {false,Req,User}
%%  {{false, <<"Bla bla bla">>},Req,State}
%%%%  case  of
%%%%     ->
%%%%      {true, Req, User};
%%%%    _ ->
%%%%      {{false, <<"Basic realm=\"cowboy\"">>}, Req, State}
%%%%  end
%%.

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