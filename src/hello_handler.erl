%%%-------------------------------------------------------------------
%%% @author С
%%% @copyright (C) 2020, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Нояб. 2020 16:58
%%%-------------------------------------------------------------------
-module(hello_handler).

-author("С").

%% API
-export([init/2, websocket_init/1]).

init(Req0, State) ->
    case cowboy_req:parse_header(<<"sec-websocket-protocol">>, Req0) of
        undefined ->
            {cowboy_websocket, Req0, State};
        Subprotocols ->
            case lists:keymember(<<"mqtt">>, 1, Subprotocols) of
                true ->
                    Req = cowboy_req:set_resp_header(<<"sec-websocket-protocol">>,
                        <<"mqtt">>, Req0),
                    {cowboy_websocket, Req, State};
                false ->
                    Req = cowboy_req:reply(400, Req0),
                    {ok, Req, State}
            end
    end.

websocket_init(State) ->
    {reply, UsersList, _} = gen_server:call(my_gen_server, {get_users}),
    JSON = jsone:encode([#{id=>U#user.id, name=>U#user.name} || U <- UsersList]),
    {[{text, JSON}], State}.


clean_user_data() -> ok.

