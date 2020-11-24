%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Нояб. 2020 12:51
%%%-------------------------------------------------------------------
-module(messages_gen_server).
-behaviour(gen_server).
-author("С").
-include("user.hrl").
-include("messages.hrl").
%% API
-export([start_link/0, handle_cast/2, handle_info/2, init/1, terminate/2, code_change/3]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    init_ets_users(),
    init_dets_messages(),
    {ok, []}.

init_dets_messages() ->
    dets:open_file(messages, [{keypos, #message.id}, {file, "./messages"}]).

init_ets_users() ->
    ets:new(users, [set, public, named_table, {keypos, #user.login}]),
    {ok, UsersList} = file:consult([code:priv_dir(chat), "/users.txt"]),
    RecordUserList = lists:map(fun(User)->
        #user{
            id = maps:get(id, User),
            login = maps:get(login, User),
            password = maps:get(password, User)
        } end, UsersList),
    ets:insert(users, RecordUserList).

handle_cast({handle_msg, ToLogin, FromLogin, MsgInfo}, State) ->
    CurrTime = erlang:system_time(millisecond),
    MsgMapInfo = #{
        u_to => ToLogin,
        u_from => FromLogin,
        id => MsgInfo#message.id,
        msg => MsgInfo#message.msg,
        date => CurrTime
    },
    FullMsgMapInfo = #{type=><<"message">>, data=>MsgMapInfo},
    dets:insert(messages, MsgInfo#message{date=CurrTime}),
    PidFrom = ets:lookup_element(users, FromLogin, #user.pid),
    PidTo = ets:lookup_element(users, ToLogin, #user.pid),
    is_pid(PidFrom) andalso (PidFrom ! {send_msg, FullMsgMapInfo}),
    is_pid(PidTo) andalso (PidTo ! {send_msg, FullMsgMapInfo}),
    {noreply, State}.

handle_info(_Msg, State) ->
    {noreply, State}.

terminate(normal, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
