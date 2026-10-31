% A Prolog interperter written in Prolog (Meta-Interpreter)
% Used to solve goals just like Prolog, but record the proof steps

:- module(interpreter,
          [ prove/2,
            proof_text/2,
            proof_leaves/2
          ]).

:- meta_predicate prove(:, -).

prove(M:Goal, Proof) :-
    prove_(Goal, M, Proof).

prove_(true, _, true) :- !.
prove_((A, B), M, (PA, PB)) :- !,
    prove_(A, M, PA),
    prove_(B, M, PB).
prove_(\+ G, M, not(G)) :- !,
    \+ call(M:G).
prove_(G, M, rule(G, BodyProof)) :-
    interpretable(M, G),
    !,
    clause(M:G, Body),
    prove_(Body, M, BodyProof).
prove_(G, M, fact(G)) :-
    call(M:G).

interpretable(M, G) :-
    callable(G),
    predicate_property(M:G, defined),
    \+ predicate_property(M:G, imported_from(_)),
    \+ predicate_property(M:G, built_in),
    \+ predicate_property(M:G, foreign).

% The base facts a proof rests on.
proof_leaves(true, []) :- !.
proof_leaves((A, B), L) :- !,
    proof_leaves(A, LA),
    proof_leaves(B, LB),
    append(LA, LB, L).
proof_leaves(fact(G), [G]) :- !.
proof_leaves(not(G), [not(G)]) :- !.
proof_leaves(rule(_, B), L) :-
    proof_leaves(B, L).

%   Indented, human-readable rendering of a proof tree.
proof_text(Proof, Text) :-
    with_output_to(string(Text), print_proof(Proof, 0)).

print_proof(true, _) :- !.
print_proof((A, B), D) :- !,
    print_proof(A, D),
    print_proof(B, D).
print_proof(fact(G), D) :- !,
    indent(D),
    format("~q~n", [G]).
print_proof(not(G), D) :- !,
    indent(D),
    format("\\+ ~q~n", [G]).
print_proof(rule(G, B), D) :-
    indent(D),
    format("~q~n", [G]),
    D1 is D + 1,
    print_proof(B, D1).

indent(D) :-
    N is D * 2,
    format("~*c", [N, 32]).