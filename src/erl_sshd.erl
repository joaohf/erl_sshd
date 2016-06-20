-module(erl_sshd).
-behaviour(gen_server).
-define(SERVER, ?MODULE).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    gen_server:start_link(?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(_) ->
    Passwords = application:get_env(erl_sshd, passwords, []),
    Pwdfun = application:get_env(erl_sshd, pwdfun, undefined),
    Port = application:get_env(erl_sshd, port, 11111),
    MasterApp = application:get_env(erl_sshd, app, erl_sshd),
    PrivDir = filename:join([code:priv_dir(MasterApp), "erl_sshd"]),
    gen_server:cast(self(), start),
    {ok, #{port => Port,
           priv_dir => PrivDir,
           passwords => Passwords,
	   pwdfun => Pwdfun,
           pid => undefined}}.

handle_call(Request, _From, State) ->
    {stop, {unimplemented, call, Request}, State}.

handle_cast(start, State) ->
    {ok, Pid} = start_daemon(State),
    link(Pid),
    {noreply, State#{pid => Pid}, hibernate};
handle_cast(Msg, State) ->
    {stop, {unimplemented, cast, Msg}, State}.

handle_info(Info, State) ->
    {stop, {unimplemented, info, Info}, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------

start_daemon(#{port := Port,
	       priv_dir := PrivDir,
	       passwords := Passwords,
	       pwdfun := undefined}) ->
    ssh:daemon(Port, [{system_dir, PrivDir},
		      {user_dir, PrivDir},
		      {user_passwords, Passwords}]);
start_daemon(#{port := Port,
	       priv_dir := PrivDir,
	       passwords := [],
	       pwdfun := Pwdfun}) ->
    ssh:daemon(Port, [{system_dir, PrivDir},
		      {user_dir, PrivDir},
		      {pwdfun, Pwdfun}]).
