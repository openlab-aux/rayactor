%%% This file is part of the RayActor Lighting Software.
%%%
%%% RayActor is free software: you can redistribute it and/or modify it under
%%% the terms of the GNU Affero General Public License as published by the Free
%%% Software Foundation, either version 3 of the License, or (at your option)
%%% any later version.
%%%
%%% RayActor is distributed in the hope that it will be useful, but WITHOUT ANY
%%% WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
%%% FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for
%%% more details.
%%%
%%% You should have received a copy of the GNU Affero General Public License
%%% along with Rayactor. If not, see <http://www.gnu.org/licenses/>.
%%%
-module(rayactor_tcp_server).
-behaviour(gen_server).

-export([start_link/1]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2,
         code_change/3]).

-spec start_link(gen_tcp:socket()) ->
    {ok, pid()} | ignore | {error, {already_started, pid()} | term()}.

start_link(LSock) ->
    gen_server:start_link(?MODULE, {LSock, self()}, [{debug, [trace]}]).

-spec init({gen_tcp:socket(), pid()}) -> {ok, #{}}.

init({LSock, Parent}) ->
    self() ! {accept, LSock, Parent},
    {ok, #{}}.

handle_info({accept, LSock, Parent}, #{}) ->
    case gen_tcp:accept(LSock) of
        {ok, Socket} ->
            {ok, _} = supervisor:start_child(Parent, []),
            inet:setopts(Socket, [{active, once}, {buffer, 2}, {packet, raw}]),
            {noreply, #{sock => Socket}};
        {error, Err} -> {stop, {error, Err}}
    end;

handle_info({tcp, Socket, <<P:1, _:7, Key:8>>}, #{sock := Socket} = State) ->
    io:format("Pressed: ~p; Key: ~p~n", [P, Key]),
    inet:setopts(Socket, [{active, once}]),
    {noreply, State};

handle_info({tcp, Socket, _}, #{sock := Socket} = State) ->
    inet:setopts(Socket, [{active, once}]),
    {noreply, State};

handle_info({tcp_closed, Socket}, #{sock := Socket} = State) ->
    {stop, normal, State}.

handle_call(_Msg, _From, State) ->
    {noreply, State}.

handle_cast(_Request, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.