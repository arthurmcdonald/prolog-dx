:- use_module(library(main)).
:- use_module(library(option)).
:- use_module(prolog/kb).
:- use_module(prolog/api).

:- initialization(main, main).

main(Argv) :-
    argv_options(Argv, _Positional, Options),
    option(port(Port), Options, 8080),
    option(kb(KB), Options, 'data/toy/toy_kb.pl'),
    kb_load(KB),
    start_server(Port),
    format(user_error, "dx-prolog listening on http://localhost:~w (kb: ~w)~n",
           [Port, KB]),
    thread_get_message(_). % block forever
