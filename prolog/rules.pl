% Expert system rules 

:- module(rules, [advice/3]).
:- use_module(library(lists)).
:- use_module(kb).

% evidence helpers (defined here, so the meta-interpreter opens them)
reported_present(evidence(Present, _), S) :- member(S, Present).

has_symptom(Evidence, Name) :-
    reported_present(Evidence, S),
    symptom(S, Name).

% red-flag symptoms: any one of these triggers urgent advice
red_flag('chest pain',
         'Chest pain can signal a medical emergency. Seek urgent care.').
red_flag(dyspnea,
         'Difficulty breathing needs prompt medical attention.').
red_flag('stiff neck',
         'A stiff neck, especially with fever or headache, needs urgent evaluation.').

advice(Evidence, urgent, Message) :-
    has_symptom(Evidence, Name),
    red_flag(Name, Message).

% combinations
advice(Evidence, urgent, 'Fever with headache and a stiff neck is a classic warning pattern; seek emergency care.') :-
    has_symptom(Evidence, fever),
    has_symptom(Evidence, headache),
    has_symptom(Evidence, 'stiff neck').

advice(Evidence, caution, 'Fever together with a cough and shortness of breath may indicate a lung infection.') :-
    has_symptom(Evidence, fever),
    has_symptom(Evidence, cough),
    has_symptom(Evidence, dyspnea).

% only when nothing alarming was found
advice(Evidence, info, 'No red-flag symptoms were reported. Rest, fluids and monitoring are usually reasonable, but see a clinician if symptoms persist or worsen.') :-
    \+ advice_red_flag(Evidence),
    has_any_evidence(Evidence).

has_any_evidence(evidence([_|_], _)).

advice_red_flag(Evidence) :-
    has_symptom(Evidence, Name),
    red_flag(Name, _).