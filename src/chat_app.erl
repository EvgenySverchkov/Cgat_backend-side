%%%-------------------------------------------------------------------
%% @doc chat public API
%% @end
%%%-------------------------------------------------------------------

-module(chat_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [{"/", hello_handler, []}]}
    ]),
    {ok, _} = cowboy:start_clear(my_http_listener,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
%%    my_gen_server:start_link(),
    chat_sup:start_link().

stop(_State) ->
    ok = cowboy:stop_listener(hello_handler).

%% internal functions
