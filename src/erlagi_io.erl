-module(erlagi_io).

-author("Marcelo Gornstein <marcelog@gmail.com>").
-github("https://github.com/marcelog").
-homepage("http://marcelog.github.com/").
-license("Apache License 2.0").

-include("erlagi_types.hrl").
-import(gen_tcp).
-import(lists).
-import(string).
-import(erlagi_debug).
-import(erlagi_misc).

-export( [ close/1, agi_rw/2, agi_rw/3 ] ).

close(Call) when is_record(Call, agicall) ->
    F = Call#agicall.close,
    F()
.

send(Call, Text) when is_record(Call, agicall) ->
    F = Call#agicall.send,
    F(Text)
.

recv(Call) when is_record(Call, agicall) ->
    F = Call#agicall.read,
    F()
.

quote_word(Text) ->
    erlagi_misc:concat([ [ 34 ], Text, [ 34 ] ])
.

escape_quotes(Text) ->
    lists:map(
        fun(Char) ->
            case Char of
                34 -> [ 92, 34 ];
                _ -> Char
            end
        end,
        Text
    )
.

quote_arguments(Arguments) when is_list(Arguments) ->
    lists:map(fun(Text) -> quote_word(escape_quotes(Text)) end, Arguments)
.

form_arguments(Arguments) when is_list(Arguments) ->
    string:join(quote_arguments(Arguments), [ 32 ])
.

form_agi_cmd(Command, Arguments) when is_list(Arguments) ->
    erlagi_misc:concat([ Command, [ 32 ], form_arguments(Arguments) ])
.

remove_eol(Text) ->
    Text -- [ 10 ] % \n
.

agi_rw(Call, Command, Arguments) when is_list(Arguments), is_record(Call, agicall) ->
    Cmd = form_agi_cmd(Command, Arguments),
    send(Call, erlagi_misc:concat( [ Cmd, [ 10 ] ])),
    Result = erlagi_result:parse_result(Cmd, remove_eol(recv(Call))),
    Result
.

agi_rw(Call, Command) when is_record(Call, agicall) ->
    agi_rw(Call, Command, [])
.

