%%%=============================================================================
%%% @copyright (C) 2015, Erlang Solutions Ltd
%%% @author Marc Sugiyama <marc.sugiyama@erlang-solutions.com>
%%% @doc erl_sshd test
%%% @end
%%%=============================================================================
-module(erl_sshd_SUITE).
-copyright("2015, Erlang Solutions Ltd.").

%% Note: This directive should only be used in test suites.
-compile(export_all).
-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").

-define(PORT, 15570).
-define(USERNAME, "username").
-define(PASSWORD, "password").


% create keys locally before running tests

%%%=============================================================================
%%% Callbacks
%%%=============================================================================

suite() ->
    [{timetrap,{minutes,10}}].

all() ->
    [{group, user_passwords},
     {group, pwdfun}].

groups() ->
    [{user_passwords, [sequence], [can_connect]},
     {pwdfun, [sequence], [can_connect]}].

init_per_group(user_passwords, Config) ->
    ok = application:load(erl_sshd),
    ok = set_env(port, ?PORT),
    ok = set_env(app, erl_sshd),
    ok = set_env(passwords, [{?USERNAME,?PASSWORD}]),
    application:ensure_all_started(erl_sshd),
    case is_erl_sshd_running() of
        false ->
            ct:pal(Reason = "sshd server is not running"),
            {skip, Reason};
        true ->
            Config
    end;
init_per_group(pwdfun, Config) ->
    ok = application:load(erl_sshd),
    ok = set_env(port, ?PORT),
    ok = set_env(app, erl_sshd),
    ok = set_env(pwdfun, fun ?MODULE:pwdfun/4),
    application:ensure_all_started(erl_sshd),
    case is_erl_sshd_running() of
        false ->
            ct:pal(Reason = "sshd server is not running"),
            {skip, Reason};
        true ->
            Config
    end.

end_per_group(_Group, _Config) ->
    ok = application:stop(erl_sshd),
    ok = application:unload(erl_sshd),
    ok = application:stop(ssh),
    _Config.

%%%=============================================================================
%%% Testcases
%%%=============================================================================

can_connect(_Config) ->
    %% GIVEN

    %% WHEN
    {ok, Connection} = ssh:connect("127.0.0.1", ?PORT,
                                   [{silently_accept_hosts, true},
                                    {user_interaction, false},
                                    {user, ?USERNAME},
                                    {password, ?PASSWORD}]),

    %% THEN
    ok = ssh:close(Connection).

%%%=============================================================================
%%% Internal functions
%%%=============================================================================

is_erl_sshd_running() ->
    proplists:is_defined(erl_sshd, application:which_applications()).

pwdfun(User, Password, PeerAddress, State) ->
    ct:pal("User ~s Password ~s", [User, Password]),
    true.

set_env(Key, Value) ->
    ok = application:set_env(erl_sshd, Key, Value).
