-module(mnesia_cache_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	Procs = [#{id => my_cache,
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
			modules => [my_cache_mnesia_manager]}
		],
	{ok, {{one_for_one, 1, 5}, Procs}}.
