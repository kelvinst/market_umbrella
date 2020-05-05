-module(syntax).

-export([sum/2, print/2]).

types() ->
  #{ 
    integer => 1,
    float => 1.2,
    list => [1, 2, 3],
    atom => hello,
    charlist => "world",
    string => <<"binary">>
  }.


sum(A, B) ->
  A + B.


print(Str, 1) ->
  io:format("~s~n", [Str]);


print(Str, X) when X > 1 ->
  io:format("~ss~n", [Str]).



%% Calling the functions

c(syntax).

syntax:sum(1, 2). % => 3
syntax:print(<<"apple">>, 1). % apple => ok
syntax:print(<<"orange">>, 2). % oranges => ok

