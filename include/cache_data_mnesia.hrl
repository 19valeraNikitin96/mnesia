%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Feb 2020 12:31
%%%-------------------------------------------------------------------
-author("erlang").

-record(cache_data,{key,value,end_time}).
-define(TABLE, cache_data).
