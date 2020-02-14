%%%-------------------------------------------------------------------
%%% @author erlang
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Feb 2020 11:56
%%%-------------------------------------------------------------------
-module(mnesia_observer).
-author("erlang").

-behaviour(gen_server).

%% API
-export([start_link/0, subscribe/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(mnesia_observer_state, {subscribers_pids}).

%%%===================================================================
%%% API
%%%===================================================================

%% @doc Spawns the server and registers the local name (unique)
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%% @private
%% @doc Initializes the server
-spec(init(Args :: term()) ->
  {ok, State :: #mnesia_observer_state{}} | {ok, State :: #mnesia_observer_state{}, timeout() | hibernate} |
  {stop, Reason :: term()} | ignore).
init([]) ->

  {Status, Reason} = mnesia:subscribe({table, cache_data, simple}),
  io:format("~w~w~w~n",[init_observ,Status,Reason]),
  io:format("~w~w~n",[init_pid,self()]),
  io:format("~w~w~n",[subscribers,mnesia_subscr:subscribers()]),
  {ok, #mnesia_observer_state{subscribers_pids = []}}.

%% @private
%% @doc Handling call messages
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #mnesia_observer_state{}) ->
  {reply, Reply :: term(), NewState :: #mnesia_observer_state{}} |
  {reply, Reply :: term(), NewState :: #mnesia_observer_state{}, timeout() | hibernate} |
  {noreply, NewState :: #mnesia_observer_state{}} |
  {noreply, NewState :: #mnesia_observer_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), Reply :: term(), NewState :: #mnesia_observer_state{}} |
  {stop, Reason :: term(), NewState :: #mnesia_observer_state{}}).
handle_call({updates},_From,State) ->
%%  mnesia:report_event({'table', cache_data, 'detailed'}),
  {messages, EventsList} = erlang:process_info(self(), messages),
  io:format("~w~w~n",[events,EventsList]),
%%    io:format("~w~w~n",[pid,self()]),
  {reply,EventsList,State};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

%% @private
%% @doc Handling cast messages
-spec(handle_cast(Request :: term(), State :: #mnesia_observer_state{}) ->
  {noreply, NewState :: #mnesia_observer_state{}} |
  {noreply, NewState :: #mnesia_observer_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #mnesia_observer_state{}}).
handle_cast({subscribe, PID},State) ->
  {noreply,#mnesia_observer_state{subscribers_pids = [PID|State#mnesia_observer_state.subscribers_pids]}};
handle_cast({updates}, State) ->
    mnesia:report_event({'table', cache_data, 'detailed'}),
    {messages, EventsList} = erlang:process_info(self(), messages),
    io:format("~w~w~n",[events,EventsList]),
%%    io:format("~w~w~n",[pid,self()]),
    {reply,EventsList,State};
handle_cast(_Request, State) ->
  {noreply, State}.

%% @private
%% @doc Handling all non call/cast messages
-spec(handle_info(Info :: timeout() | term(), State :: #mnesia_observer_state{}) ->
  {noreply, NewState :: #mnesia_observer_state{}} |
  {noreply, NewState :: #mnesia_observer_state{}, timeout() | hibernate} |
  {stop, Reason :: term(), NewState :: #mnesia_observer_state{}}).

handle_info({mnesia_table_event,Data},State) ->
  io:format("~w~n",[Data]),
  {Action,D,_Meta} = Data,
  Msg = jsx:encode([{<<"action">>,Action}, {<<"table">>,element(1,D)}]),
  broadcast(Msg, State#mnesia_observer_state.subscribers_pids),
  {noreply, State};
handle_info(_Info, State) ->
  {noreply, State}.

broadcast(_Msg, [])->ok;
broadcast(Msg, [H|T])->
%%  io:format("~w~w~n", [sended_to,H]),
  H ! {timeout,self(),Msg},
  broadcast(Msg, T).

%% @private
%% @doc This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #mnesia_observer_state{}) -> term()).
terminate(_Reason, _State) ->
  ok.

%% @private
%% @doc Convert process state when code is changed
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #mnesia_observer_state{},
    Extra :: term()) ->
  {ok, NewState :: #mnesia_observer_state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
%%updates()->
%%  gen_server:call(?MODULE,{updates}).
subscribe(PID)->
  gen_server:cast(?MODULE,{subscribe,PID}).

