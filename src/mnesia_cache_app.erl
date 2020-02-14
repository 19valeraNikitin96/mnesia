-module(mnesia_cache_app).
-behaviour(application).
-include("cache_data_mnesia.hrl").
-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
	mnesia:stop(),
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(cache_data, [{attributes, record_info(fields, cache_data)}]),

	Dispatch = cowboy_router:compile(
		[
			{'_', [
				{"/api/cache_server", my_cache_server, []},
				{"/", cowboy_static, {priv_file, mnesia_cache, "index.html"}},
				{"/websocket", my_cache_websocket_server, []},
				{"/static/[...]", cowboy_static, {priv_dir, mnesia_cache, "static"}}
			]
			}
		]
	),
	{ok, _} = cowboy:start_clear(my_http_listener,
		[{port, 8080}],
		#{env => #{dispatch => Dispatch}}
	),
	mnesia_cache_sup:start_link().

stop(_State) ->
	ok.
