%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Нояб. 2020 16:58
%%%-------------------------------------------------------------------
-module(messages_handler).

-behaviour(cowboy_handler).
-behaviour(cowboy_websocket).

-author("С").
-include("user.hrl").
-include("messages.hrl").

%% API
-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req0, State) ->
    Cookies = cowboy_req:parse_cookies(Req0),
    Result = lists:keyfind(<<"usersession">>, 1, Cookies),
    send_request(Result, State, Req0).

send_request(false, State, Req0) ->
    Req2 = cowboy_req:reply(401, Req0),
    {ok, Req2, State};
send_request({_, CookieToken}, State, Req0) ->
    Result = ets:lookup(sessions, CookieToken),
    send_request2(Result, State, Req0).

send_request2([], State, Req0) ->
    Req1 = cowboy_req:reply(401, Req0),
    {ok, Req1, State};
send_request2([{_, _Token, Login}], State, Req0) ->
    case cowboy_req:parse_header(<<"sec-websocket-protocol">>, Req0) of
        undefined ->
            {cowboy_websocket, Req0, [{user_login, Login}|State]};
        Subprotocols ->
            case lists:keymember(<<"mqtt">>, 1, Subprotocols) of
                true ->
                    Req = cowboy_req:set_resp_header(<<"sec-websocket-protocol">>,
                        <<"mqtt">>, Req0),
                    {cowboy_websocket, Req, [{user_login, Login}|State]};
                false ->
                    Req = cowboy_req:reply(400, Req0),
                    {ok, Req, State}
            end
    end.

websocket_init(State) ->
    {_, CurrUserLogin} = lists:keyfind(user_login, 1, State),
    ets:update_element(users, CurrUserLogin, {#user.pid, self()}),
    {ok, State}.

websocket_info({send_msg, Msg}, State) ->
    FullObj = #{type=><<"message">>, data=>Msg},
    Json = jsone:encode(FullObj),
    {reply, {text, Json}, State}.

websocket_handle({text, Value}, State) ->
    Map = jsone:decode(Value),
    Method = maps:get(<<"method">>, Map),
    Data = maps:get(<<"data">>, Map),
    method_handler(Method, Data, State);
websocket_handle(_Frame, State) ->
    {ok, State}.

method_handler(<<"get_history">>, #{<<"login">> := LoginTo}, State) ->
    CurrUserLogin = proplists:get_value(user_login, State),
    CurrUserIdFromEts = ets:lookup_element(users, CurrUserLogin, #user.id),
    ToUserIdFromEts = ets:lookup_element(users, LoginTo, #user.id),
    HistoryList = dets:foldl(
        fun(#message{u_to = To, u_from = From, id = Id, msg = Msg, date = Date}, Acc) when To == ToUserIdFromEts, From == CurrUserIdFromEts ->
            [#{u_to => LoginTo, u_from => CurrUserLogin, id => Id, msg => Msg, date => Date}|Acc];
            (#message{u_to = To, u_from = From, id = Id, msg = Msg, date = Date}, Acc) when To == CurrUserIdFromEts, From == ToUserIdFromEts ->
                [#{u_to => CurrUserLogin, u_from => LoginTo, id => Id, msg => Msg, date => Date}|Acc];
            (_,Acc) -> Acc end,
        [],
        messages),
    FullObj = #{type=> <<"history">>, data => lists:reverse(HistoryList)},
    Json = jsone:encode(FullObj),
    {reply, {text, Json}, State};

method_handler(<<"send_msg">>, #{<<"text">> := <<>>, <<"date">> := Date, <<"to">> := ToUserLogin}, State) ->
    {ok,State};
method_handler(<<"send_msg">>, #{<<"text">> := MsgText, <<"date">> := Date, <<"to">> := ToUserLogin}, State) ->
    CurrUserLogin = proplists:get_value(user_login, State),
    CurrUserIdFromEts = ets:lookup_element(users, CurrUserLogin, #user.id),
    ToUserIdFromEts = ets:lookup_element(users, ToUserLogin, #user.id),
    {Num1, Num2, Num3} = os:timestamp(),
    UniqId = Num1 + Num2 + Num3,
%%    {To, From} = if CurrUserIdFromEts > ToUserIdFromEts -> {ToUserIdFromEts, CurrUserIdFromEts};
%%                     true ->{CurrUserIdFromEts, ToUserIdFromEts}
%%                 end,
    gen_server:cast(
        messages_gen_server, {handle_msg, ToUserLogin, CurrUserLogin, #message{id = UniqId, u_to = ToUserIdFromEts, u_from = CurrUserIdFromEts, msg = MsgText, date = Date}}),
    {ok,State}.

