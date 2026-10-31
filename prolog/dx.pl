
%
%
%

:- module(dx,
          [ diagnose/3,
            resolve_evidence/3
          ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(kb).
:- use_module(engine).
:- use_module(rules).
:- use_module(interpreter).

% Map user-supplied symptom names/ids to ids; collect the ones not known.
resolve_evidence([], [], []).
resolve_evidence([T|Ts], Ids, Unknown) :-
    resolve_evidence(Ts, Ids1, Unknown1),
    (   resolve_symptom(T, Id)
    ->  Ids = [Id|Ids1], Unknown = Unknown1
    ;   Ids = Ids1,      Unknown = [T|Unknown1]
    ).

diagnose(Evidence, Limit, Report) :-
    Evidence = evidence(P0, A0),
    list_to_set(P0, P),
    list_to_set(A0, A),
    Evidence0 = evidence(P, A),
    rank(Evidence0, Limit, Ranked),
    maplist(candidate_dict, Ranked, Candidates),
    advice_list(Evidence0, Advice),
    (   next_question(Evidence0, QS, split(Have, Of))
    ->  symptom(QS, QName),
        Next = _{symptom: QS, name: QName, split: _{have: Have, of: Of}}
    ;   Next = null
    ),
    %disclaimer(Disclaimer),
    Report = _{ candidates: Candidates,
                advice: Advice,
                next_question: Next,
                disclaimer: Disclaimer
              }.

candidate_dict(r(Score, D, detail(Matched, Denied, CF, Coverage)),
               _{ disease: D,
                  name: Name,
                  score: S4,
                  confidence: Band,
                  certainty_factor: CF4,
                  coverage: Cov4,
                  matched: MatchedDicts,
                  denied: DeniedDicts,
                  not_reported: Missing
                }) :-
    disease(D, Name),
    confidence_band(Score, Band),
    round4(Score, S4),
    round4(CF, CF4),
    round4(Coverage, Cov4),
    maplist(matched_dict, Matched, MatchedDicts),
    maplist(name_dict, Denied, DeniedDicts),
    pairs_keys(Matched, MatchedIds),
    disease_symptoms(D, All),
    subtract(All, MatchedIds, MissingIds),
    maplist(symptom_name, MissingIds, Missing).

matched_dict(S-W, _{symptom: S, name: Name, weight: W4}) :-
    symptom(S, Name),
    round4(W, W4).

name_dict(S, _{symptom: S, name: Name}) :-
    symptom(S, Name).

symptom_name(S, Name) :-
    symptom(S, Name).

round4(X, Y) :-
    Y is round(X * 10000) / 10000.0.

% Run the expert rules through the meta-interpreter so each message
% carries the proof that produced it.
advice_list(Evidence, Advice) :-
    findall(_{level: Level, message: Message, because: Because},
            (   prove(rules:advice(Evidence, Level, Message), Proof),
                proof_text(Proof, Because)
            ),
            Advice0),
    list_to_set(Advice0, Advice).
