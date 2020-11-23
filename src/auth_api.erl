%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Нояб. 2020 15:22
%%%-------------------------------------------------------------------
-module(auth_api).
-author("С").
-include("session.hrl").
%% API
-export([checkUserData/1, isEmptyLoginOrPasswordField/1]).

isEmptyLoginOrPasswordField(BodyMap) ->
    BodyList = maps:to_list(BodyMap),
    check_user_info_list(BodyList, 0).

check_user_info_list([], Counter) when Counter < 2 ->
    true;
check_user_info_list([], 2) ->
    false;
check_user_info_list([{<<"login">>, <<>>}| T], Counter) ->
    check_user_info_list(T, Counter);
check_user_info_list([{<<"password">>, <<>>}| T], Counter) ->
    check_user_info_list(T, Counter);
check_user_info_list([{<<"login">>, _}| T], Counter) ->
    check_user_info_list(T, Counter+1);
check_user_info_list([{<<"password">>, _}| T], Counter) ->
    check_user_info_list(T, Counter+1);
check_user_info_list([_|T], Counter) ->
    check_user_info_list(T, Counter).

checkUserData(UserInfo) ->
    UserLogin = maps:get(<<"login">>, UserInfo),
    UserPass = maps:get(<<"password">>, UserInfo),
    UserInfoFormEts = ets:lookup(users, UserLogin),
    checkLoginAndPassword(UserInfoFormEts, UserPass).

checkLoginAndPassword([], _) -> no_validate;
checkLoginAndPassword([{_,_,Login, Password,_}], Password) ->
    SessionId = writeSessionToEts(Login),
    {Login, SessionId};
checkLoginAndPassword([{_,_,_,_,_}], _) ->
    no_validate.

writeSessionToEts(UserLogin) ->
    Salt = salt(),
    CookieToken =  hex(crypto:hmac(sha256,Salt,UserLogin,21)),
    SessionRecord = #sessionRecord{
        token = CookieToken,
        userLogin = UserLogin
    },
    ets:insert(sessions, SessionRecord),
    CookieToken.

hex(Bin) -> << <<(int_to_hex(N))>> || <<N:4>> <= Bin>>.

int_to_hex(N) when N < 10 -> $0 + N;
int_to_hex(N) when N < 16 -> $a + N - 10.

salt() -> crypto:strong_rand_bytes(20).