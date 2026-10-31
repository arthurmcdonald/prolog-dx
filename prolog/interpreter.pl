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
