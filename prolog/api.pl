:- module(api, [start_server/1, stop_server/1]).
:- use_module(library(http/thread_httpd)).
:- use_module(library(http/http_dispatch)).
:- use_module(library(http/http_json)).
:- use_module(library(http/http_parameters)).
:- use_module(library(lists)).
:- use_module(library(aggregate)).
:- use_module(kb).
:- use_module(dx).

:- http_handler(root(api/health),   handle_health,   []).
:- http_handler(root(api/symptoms), handle_symptoms, []).
:- http_handler(root(api/disease),  handle_disease,  []).
:- http_handler(root(api/diagnose), handle_diagnose, [method(post)]).

start_server(Port) :-
    http_server(http_dispatch, [port(Port)]).

stop_server(Port) :-
    http_stop_server(Port, []).

% request mapings

get_health(_Request) :-
    disease_count(Diseases),
    aggregate_all(count, symptom(_, _), Symptoms),
    findall(K-V, kb_meta(K, V), Meta0),
    dict_pairs(Meta, meta, Meta0),
    reply_json_dict(_{ status: ok,
                       diseases: Diseases,
                       symptoms: Symptoms,
                       source: Meta }).

get_symptoms(Request) :-
    http_parameters(Request,
                    [ q(Q,         [default('')]),
                      limit(Limit, [integer, default(20)])
                    ]),
    search_symptoms(Q, Limit, Matches),
    findall(_{id: Id, name: Name}, member(Id-Name, Matches), Dicts),
    reply_json_dict(_{ symptoms: Dicts }).

get_disease(Request) :-
    http_parameters(Request, [id(Id, [atom])]),
    (   kb:disease(Id, Name)
    ->  disease_symptoms(Id, Ids),
        findall(_{id: S, name: SN}, ( member(S, Ids), kb:symptom(S, SN) ), Ss),
        reply_json_dict(_{ id: Id, name: Name, symptoms: Ss })
    ;   reply_json_dict(_{ error: "unknown disease id" }, [status(404)])
    ).

post_diagnose(Request) :-
    catch(http_read_json_dict(Request, In), _,
          ( reply_json_dict(_{ error: "request body must be valid JSON" },
                            [status(400)]),
            fail )),
    !,
    get_list(present, In, PText),
    get_list(absent,  In, AText),
    (   get_dict(limit, In, Limit), integer(Limit), Limit > 0
    ->  true
    ;   Limit = 5
    ),
    resolve_evidence(PText, Present, UnknownP),
    resolve_evidence(AText, Absent,  UnknownA),
    append(UnknownP, UnknownA, Unknown),
    (   Present == []
    ->  reply_json_dict(_{ error: "provide at least one known symptom in \"present\"",
                           unknown_symptoms: Unknown },
                        [status(400)])
    ;   diagnose(ev(Present, Absent), Limit, Report0),
        Report = Report0.put(unknown_symptoms, Unknown),
        reply_json_dict(Report)
    ).

post_diagnose(_). % error reply already sent

get_list(Key, Dict, List) :-
    (   get_dict(Key, Dict, L), is_list(L)
    ->  List = L
    ;   List = []
    ).
