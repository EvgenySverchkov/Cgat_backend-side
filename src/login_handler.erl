%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Нояб. 2020 18:11
%%%-------------------------------------------------------------------
-module(login_handler).
-author("С").

%% API
-export([init/2]).
-define(HEADERS, #{
    <<"content-type">> => <<"application/json">>,
    <<"Access-Control-Allow-Origin">> => <<"http://localhost:3000">>,
    <<"Access-Control-Allow-Headers">> => <<"Content-Type">>,
    <<"Access-Control-Allow-Credentials">> => <<"true">>}).

init(Req0 = #{method := <<"POST">>, body_length := 0}, State) ->
    Req = cowboy_req:reply(200, ?HEADERS, json_wrong_msg(<<"Body is empty">>), Req0),
    {ok, Req, State};
init(Req0 = #{method := <<"POST">>}, State) ->
    Res = cowboy_req:binding(type, Req0),
    handlePath(Res, Req0, State);
init(Req0 = #{method := <<"OPTIONS">>}, State) ->
    Req = cowboy_req:reply(200, ?HEADERS, Req0),
    {ok, Req, State};
init(Req0, State) ->
    Req = cowboy_req:reply(405, ?HEADERS, Req0),
    {ok, Req, State}.


postHandler(no_validate, Req0) ->
    cowboy_req:reply(200, ?HEADERS, json_wrong_msg(<<"Wrong login or password">>), Req0);
postHandler({Login, SessionId}, Req0) ->
    ReqJson = jsone:encode(#{success=>true, msg=><<"Success login">>, login => Login}),
    Req1 = cowboy_req:set_resp_cookie(<<"usersession">>, SessionId, Req0, #{max_age => 3600000, path => "/", http_only => false, same_site => lax}), %%todo: rename cookie, save map to const
    cowboy_req:reply(200, ?HEADERS, ReqJson, Req1).

json_wrong_msg(Message) -> jsone:encode(#{success=>false, msg=> Message}).

handlePath(<<"login">>, Req0, State) ->
    {_, Body, _} = cowboy_req:read_body(Req0),
    UserInfo = jsone:decode(Body),
    case auth_api:isEmptyLoginOrPasswordField(UserInfo) of
        true ->
            Req = cowboy_req:reply(
                200,
                ?HEADERS,
                json_wrong_msg(<<"Login or password is field empty">>),
                Req0),
            {ok, Req, State};
        false ->
            LoginResult = auth_api:checkUserData(UserInfo),
            Req = postHandler(LoginResult, Req0),
            {ok, Req, State}
    end;
handlePath(<<"check_login">>, Req0, State) ->
    Cookies = cowboy_req:parse_cookies(Req0),
    Result = lists:keyfind(<<"usersession">>, 1, Cookies),
    check_token(Result, State, Req0).

check_token(false, State, Req0) ->
    Req2 = cowboy_req:reply(200, ?HEADERS, jsone:encode(#{success=>false}),Req0),
    {ok, Req2, State};

check_token({_, CookieToken}, State, Req0) ->
    Result = ets:lookup(sessions, CookieToken),
    check_token2(Result, State, Req0).

check_token2([], State, Req0) ->
    Req1 = cowboy_req:reply(200, ?HEADERS, jsone:encode(#{success=>false}),Req0),
    {ok, Req1, State};

check_token2([{_, _Token, Login}], State, Req0) ->
    Req1 = cowboy_req:reply(200, ?HEADERS, jsone:encode(#{success=>true}),Req0),
    {ok, Req1, State}.