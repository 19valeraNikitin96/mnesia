-module(mnesia_cache_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	Procs = [
		#{id => my_cache,
		start => {my_cache, start_link, []},
		restart => permanent,
		shutdown => brutal_kill,
		type => worker,
		modules => [my_cache]},
		#{id => my_cache_mnesia_manager,
			start => {my_cache_mnesia_manager, start_link, []},
			restart => permanent,
			shutdown => brutal_kill,
			type => worker,
			modules => [my_cache_mnesia_manager]},
		#{id => mnesia_observer,
			start => {mnesia_observer, start_link, []},
			restart => permanent,
			shutdown => brutal_kill,
			type => worker,
			modules => [mnesia_observer]}
%%		,
%%		#{id => my_cache_websocket_server,
%%			start => {my_cache_websocket_server, start_link, []},
%%			restart => permanent,
%%			shutdown => brutal_kill,
%%			type => worker,
%%			modules => [my_cache_websocket_server]}
		],
	{ok, {{one_for_one, 1, 5}, Procs}}.
