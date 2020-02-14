%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Feb 2020 16:36
%%%-------------------------------------------------------------------
-module(my_cache_websocket_auth_server).

-author("erlang").

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).

init(Req, Opts) ->
  {cowboy_websocket, Req, Opts,#{idle_timeout=>30000}}.

websocket_init(State) ->
  erlang:start_timer(1000, self(), <<"Hello!">>),
  {[], State}.

websocket_handle({text, Msg}, State) ->
  Map = jsx:decode(Msg, [return_maps]),
  {_,Login} = maps:find(<<"login">>,Map),
  {_,Password} = maps:find(<<"password">>,Map),
  case Login =:= <<"ADMIN">> andalso Password =:= <<"ADMIN">> of
    true ->
      {ok,Jwt} = jwt:encode(hs256,[{name, <<"ADMIN">>},{age, <<"ADMIN">>}],<<"secret">>),
      io:format("~w~w~n",[encoded_jwt,Jwt]),
      io:format("~w~w~n",[decoded_jwt,jwt:decode(Jwt,<<"secret">>)]),
      {[{text,Jwt}], State};
    false -> {[{text, << "That's what she said! ",Msg/binary >>}], State}
  end;
websocket_handle(_Data, State) ->
  {[], State}.
websocket_info({timeout,_Ref,Msg},State) ->
  {[{text, Msg}],State};
websocket_info(_Info, State) ->
  {[], State}.
