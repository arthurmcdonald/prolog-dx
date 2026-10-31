% The Knowledge Base
% Keeps the dynamic facts
% Loads the data (from a file) for the Knowledge Base

:- module(kb,
          [ disease/2,
            symptom/2,
            presents/2,
            kb_meta/2,
            disease_count/1,
            symptom_df/2,
            kb_load/1,
            kb_clear/0,
            disease_symptoms/2,
            resolve_symptom/2,
            search_symptoms/3
          ]).
:- use_module(library(lists)).
:- use_module(library(aggregate)).

:- dynamic disease/2, symptom/2, presents/2, kb_meta/2,
           disease_count/1, symptom_df/2.

% clear the knowledge base
kb_clear :-
    retractall(disease(_, _)),
    retractall(symptom(_, _)),
    retractall(presents(_, _)),
    retractall(kb_meta(_, _)),
    retractall(disease_count(_)),
    retractall(symptom_df(_, _)).

%   Replace the current knowledge base with the facts in File.
kb_load(File) :-
    kb_clear,
    setup_call_cleanup(
        open(File, read, In, [encoding(utf8)]),
        read_facts(In, File),
        close(In)),
    kb_index.

read_facts(In, File) :-
    read_term(In, Term, []),
    (   Term == end_of_file
    ->  true
    ;   store(Term, File),
        read_facts(In, File)
    ).

store(disease(I, N), _)   :- !, assertz(disease(I, N)).
store(symptom(I, N), _)   :- !, assertz(symptom(I, N)).
store(kb_meta(K, V), _)   :- !, assertz(kb_meta(K, V)).
store(presents(D, S), _)  :-
    !,
    (presents(D, S) -> true ; assertz(presents(D, S))).
store(Other, File) :-
    print_message(warning, format("~w: ignoring ~q", [File, Other])).

% (Re)compute disease_count/1 and symptom_df/2.
kb_index :-
    retractall(disease_count(_)),
    retractall(symptom_df(_, _)),
    aggregate_all(count, disease(_, _), N),
    assertz(disease_count(N)),
    forall(symptom(S, _),
           (   aggregate_all(count, presents(_, S), DF),
               assertz(symptom_df(S, DF))
           )).

disease_symptoms(D, Ss) :-
    findall(S, presents(D, S), Ss).

% Text may be an id or a (case-insensitive) name; string or atom.
resolve_symptom(Text, Id) :-
    text_to_string(Text, Str),
    atom_string(Atom, Str),
    (   symptom(Atom, _)
    ->  Id = Atom
    ;   downcase_atom(Atom, Lower),
        symptom(Id, Lower)
    ->  true
    ).

% Matches is a list of Id-Name whose name contains Query (case-insens.).
search_symptoms(Query, Limit, Matches) :-
    text_to_string(Query, QS),
    string_lower(QS, Lower),
    findall(Name-Id,
            (   symptom(Id, Name),
                sub_atom(Name, _, _, _, Lower)
            ),
            Pairs0),
    msort(Pairs0, Pairs),
    length(Pairs, Len),
    (   Len =< Limit
    ->  Taken = Pairs
    ;   length(Taken, Limit), append(Taken, _, Pairs)
    ),
    findall(Id-Name, member(Name-Id, Taken), Matches).
