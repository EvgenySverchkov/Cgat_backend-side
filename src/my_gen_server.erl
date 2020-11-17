%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Нояб. 2020 12:51
%%%-------------------------------------------------------------------
-module(my_gen_server).
-behaviour(gen_server).
-author("С").
-include("user.hrl").
%% API
-export([start_link/0, handle_call/3, handle_cast/2, handle_info/2, init/1, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    ets:new(users, {set, private, named_table, {keypos, 1}}),
    {ok, UsersList} = file:consult([code:priv_dir(chat), "/users.txt"]),
    RecordUserList = lists:map(fun(User)->
        #user{
            id = maps:get(id, User),
            name = maps:get(name, User),
            password = maps:get(password, User),
            pid = maps:get(pid, User)
        } end, UsersList),
    ets:insert(users, RecordUserList),
    {ok, []}.

handle_call({get_users}, _Form, State) ->
    List = ets:tab2list(users),
    {reply, List, State}.

handle_cast({Some}, State) -> {noreply, State}.

handle_info(Msg, State) ->
    {noreply, State}.

terminate(normal, State) ->
    io:format("TREMINATE!!!!!!!!!!"),
    ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
