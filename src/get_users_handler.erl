%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Нояб. 2020 21:57
%%%-------------------------------------------------------------------
-module(get_users_handler).
-author("С").
-include("user.hrl").

%% API
-export([init/2]).

-define(HEADERS, #{
    <<"content-type">> => <<"application/json">>,
    <<"Access-Control-Allow-Origin">> => <<"http://localhost:3000">>,
    <<"Access-Control-Allow-Headers">> => <<"Content-Type">>,
    <<"Access-Control-Allow-Credentials">> => <<"true">>}).

init(Req0 = #{method := <<"POST">>}, State) ->
    Cookies = cowboy_req:parse_cookies(Req0),
    Result = lists:keyfind(<<"usersession">>, 1, Cookies),
    check_session(Result, Req0, State);

init(Req0 = #{method := <<"OPTIONS">>}, State) ->
    Req = cowboy_req:reply(200, ?HEADERS, Req0),
    {ok, Req, State}.

handler(Login) ->
    UsersList = get_users(Login),
    jsone:encode([#{id=>U#user.id, name=>U#user.login} || U <- UsersList]).

get_users(CurrUserLogin) ->
    List = ets:tab2list(users),
    lists:filter(
        fun ({_,_, Login, _,_}) when Login =/= CurrUserLogin -> true;
            (_) -> false end,
        List).

check_session({_, CookieToken}, Req0, State) ->
    case ets:lookup(sessions, CookieToken) of
        [{_, _Token, Login}] ->
            Req1 = cowboy_req:reply(200, ?HEADERS, handler(Login), Req0),
            {ok, Req1, State};
        [] ->
            Req1 = cowboy_req:reply(401, Req0),
            {ok, Req1, State}
    end;

check_session(false, Req0, State) ->
    Req2 = cowboy_req:reply(401, ?HEADERS, Req0),
    {ok, Req2, State}.