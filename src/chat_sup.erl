%%%-------------------------------------------------------------------
%% @doc chat top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(chat_sup).

-behaviour(supervisor).

-include("session.hrl").

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional



init([]) ->
    init_ets_sessions(),
    SupFlags = #{strategy => one_for_all,
                 intensity => 0,
                 period => 1},
    ChildSpecs = [{
        messages_gen_server,
        {messages_gen_server,start_link,[]},
        permanent,
        5000,
        worker,
        [messages_gen_server]}],
    {ok, {SupFlags, ChildSpecs}}.

%% internal functions

init_ets_sessions() ->
    ets:new(sessions, [set, public, named_table, {keypos, #sessionRecord.token}]).