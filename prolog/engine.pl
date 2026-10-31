% The scoring engine - how to score disease D based on sypmtoms S
%
% Evidence is a term with two lists - Present and Absent Symptoms the patient discloses
%
% score = CF * cov_factor * deny_penalty ^ |denied symptoms of D|
% cov_factor = (1 - L) + L * matched/|symptoms(D)|
% CF = certainty factor using MYCIN-style, used for weights
% If a symptom is Absent and a disease presents that symptom then add a penalty (deny_penalty)

:- module(engine,
          [ param/2,
            specificity/2,
            rank/3,
            score/4,
            confidence_band/2
          ]).
:- use_module(library(lists)).
:- use_module(library(apply)).
:- use_module(library(pairs)).
:- use_module(library(aggregate)).
:- use_module(kb).

param(max_weight, 0.9). % no single symptom is ever 100% conclusive
param(coverage_mix, 0.5). % L in the cov_factor formula
param(deny_penalty, 0.7).
param(band_high, 0.6).
param(band_medium, 0.3).
param(question_pool, 8).

% Fails for symptoms that no disease presents.
specificity(S, W) :-
    symptom_df(S, DF),
    DF > 0,
    disease_count(N),
    param(max_weight, Max),
    (   N > 1
    ->  W is Max * log(N / DF) / log(N)
    ;   W = Max
    ).

% Fails for diseases with no matching reported symptom.
% Detail = detail(Matched:list(Symptom-Weight), Denied:list, CF, Coverage)
score(evidence(Present0, Absent0), D, Score, detail(Matched, Denied, CF, Coverage)) :-
    list_to_set(Present0, Present),
    list_to_set(Absent0, Absent),
    disease(D, _),
    findall(S-W,
            ( member(S, Present), presents(D, S), specificity(S, W) ),
            Matched),
    Matched \== [],
    pairs_values(Matched, Ws),
    foldl(cf_step, Ws, 0.0, CF),
    disease_symptoms(D, All),
    length(All, NAll),
    length(Matched, NM),
    Coverage is NM / NAll,
    param(coverage_mix, L),
    CovFactor is 1 - L + L * Coverage,
    findall(S, ( member(S, Absent), presents(D, S) ), Denied),
    length(Denied, ND),
    param(deny_penalty, Pen),
    Score is CF * CovFactor * Pen ** ND.

cf_step(W, CF0, CF) :-
    CF is CF0 + W * (1 - CF0).

% Ranked is a list of r(Score, Disease, Detail), best first, Score > 0.
rank(Evidence, Limit, Ranked) :-
    findall(r(Score, D, Detail),
            (score(Evidence, D, Score, Detail), Score > 0),
            Rs),
    sort(1, @>=, Rs, Sorted),
    take(Limit, Sorted, Ranked).

take(N, List, Prefix) :-
    length(List, Len),
    (   Len =< N
    ->  Prefix = List
    ;   length(Prefix, N),
        append(Prefix, _, List)
    ).

confidence_band(Score, Band) :-
    param(band_high, H),
    param(band_medium, M),
    (   Score >= H -> Band = high
    ;   Score >= M -> Band = medium
    ;   Band = low
    ).

