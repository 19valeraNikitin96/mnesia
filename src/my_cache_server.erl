%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Feb 2020 12:46
%%%-------------------------------------------------------------------
-module(my_cache_server).
-author("erlang").
-include("cache_data_mnesia.hrl").
-include_lib("stdlib/include/qlc.hrl").
-include("header.hrl").
%% API
-export([init/2]).
-export([]).

init(Req0, Opts) ->
	Method = cowboy_req:method(Req0),
	HasBody = cowboy_req:has_body(Req0),
	Req = handler(Method, HasBody, Req0),
	{ok, Req, Opts}.

handler(<<"POST">>, true, Req0)->
	{ok, KeyValues, Req1} = cowboy_req:read_urlencoded_body(Req0),
	[{Data, _}|[]] = KeyValues,
	Map = jsx:decode(Data, [return_maps]),
	{_,Act}=maps:find(<<"action">>,Map),
	Body = data_handler(Act, maps:remove(Act, Map)),
	cowboy_req:reply(200,#{<<"content-type">> => <<"application/json">>},Body,Req1).

data_handler(<<"insert">>, Map) ->
	{_, K} = maps:find(<<"key">>, Map),
	{_, V} = maps:find(<<"value">>, Map),
	Row = #cache_data{key = K,value = V,end_time = erlang:system_time('second')+60},
	F = fun()->mnesia:write(Row) end,
	mnesia:transaction(F),
	jsx:encode([{<<"result">>, <<"ok">>}]);
data_handler(<<"lookup">>, Map)->
	{_, K} = maps:find(<<"key">>, Map),
	F = fun()->mnesia:read(cache_data, K) end,
	Res = mnesia:transaction(F),
	io:format("~w~n", [Res]),
	case Res of
		{'atomic',[{cache_data,K,Value,_EndTime}]} -> jsx:encode([{<<"result">>, Value}]);
		_ -> jsx:encode([{<<"result">>, <<"undefined">>}])
	end;

data_handler(<<"lookup_by_date">>, Map)->
	{_, DF} = maps:find(<<"date_from">>, Map),
	{_, DT} = maps:find(<<"date_to">>, Map),
	FS = my_cache_impl:date_to_seconds(DF),
	TS = my_cache_impl:date_to_seconds(DT),
	F = fun()->qlc:eval(qlc:q([X#cache_data.value || X <- mnesia:table(?TABLE), X#cache_data.end_time >= FS, X#cache_data.end_time =< TS])) end,
	{'atomic', Res} = mnesia:transaction(F),
	jsx:encode([{<<"result">>, Res}]).