# prolog-dx

A rule-based **symptom → disease diagnostic expert system** in SWI-Prolog, built on a real
biomedical knowledge graph, with explainable answers and a small JSON HTTP API.

> **Educational project only. Not medical advice.** The underlying associations are
> literature co-occurrence, not clinical frequencies. (see [Limitations](#limitations)).

## Quick start

```bash
# needs SWI-Prolog 9.x  (https://www.swi-prolog.org/download/stable)
make run-fake # serve on :8080 using the tiny built-in toy KB
```

Real data (needs `curl` and `python3`):

```bash
make data        # downloads Hetionet, builds data/kb/hetionet_kb.pl
make run
```

Or with Docker: `make docker && docker run -p 8080:8080 prolog-dx`.

## Knowledge-base schema

Plain Prolog facts, one per line (`data/toy/toy_kb.pl` is the reference example):

```prolog
disease(Id, Name). % Id: atom, Name: lower-case atom
symptom(Id, Name).
presents(DiseaseId, SymptomId).
kb_meta(Key, Value). % provenance: source, license, url
```

At load time `kb_index/0` derives `disease_count/1` and `symptom_df/2` (in how many diseases each symptom appears). The loader only accepts these four fact shapes

**Real dataset:** [Hetionet](https://github.com/hetio/hetionet) (CC0) `DpS` ("Disease *presents* Symptom") edges, which derive from the MeSH/MEDLINE symptom–disease network of Zhou et al. (2014). `scripts/etl_hetionet.py` turns them into the facts above.

## Rule layout

```
 evidence(Present, Absent)
        │
        ▼
┌─ engine.pl ─────────────────────────────────────────────┐
│ score/4   per disease: Σ-combined symptom weights       │
│ rank/3    sort, drop zero scores, take top N            │
│ next_question/3   symptom that best splits the top-N    │
└─────────────────────────────────────────────────────────┘
        │                          ┌─ rules.pl ───────────┐
        │                          │ advice/3 expert rules│
        │                          │ (red flags, combos)  │
        │                          └──────────┬───────────┘
        │                                     │ run through
        │                          ┌─ explain.pl ─────────┐
        │                          │ prove/2 → proof tree │
        ▼                          └──────────┬───────────┘
┌─ dx.pl ─ diagnose/3 ─ assembles one JSON-ready dict ◄───┘
        ▼
┌─ api.pl ─ HTTP/JSON ─┐
```

### Scoring model

For each disease *D* and the reported symptoms that *D* presents:

1. **Weight** of a symptom *S*: `w(S) = 0.9 · ln(N / df(S)) / ln(N)`, where *N* is the number of diseases and *df* the number presenting *S*. Rare symptoms are strong evidence, ubiquitous ones are weak. The 0.9 cap means no single symptom is ever conclusive
2. **Combine** as certainty factors: `CF ← CF + w·(1 − CF)`, starting from 0
3. **Coverage:** scale by `0.5 + 0.5 · matched/|symptoms(D)|` so diseases whose whole picture is explained by ones that match by chance
4. **Denials:** each explicitly denied symptom of *D* multiplies the score by 0.7

All constants are `engine:param/2` facts. `tests/scoring_replica.py` is an independent Python
implementation used to derive the expected values in the Prolog tests.

### Expert rules and explanations

`rules.pl` holds readable rules such as:

```prolog
advice(Ev, urgent, Message) :-
    has_symptom(Ev, Name),
    red_flag(Name, Message).
```

`explain:prove/2` is a vanilla meta-interpreter that opens up only the predicates defined in the rules module and records each step, so the API returns not just *what* advice fired but the **proof** (`because`) showing which reported symptoms triggered it.

## API Documentation

| Method | Path | Notes |
|---|---|---|
| GET | `/api/health` | KB size and provenance |
| GET | `/api/symptoms?q=fev&limit=20` | search symptom names |
| GET | `/api/disease?id=influenza` | a disease and its symptoms |
| POST | `/api/diagnose` | see curl example below |

```bash
curl -s -X POST localhost:8080/api/diagnose -H 'content-type: application/json' \
  -d '{"present": ["fever", "cough", "sore throat"], "absent": ["headache"], "limit": 3}'
```

Symptoms may be names (case-insensitive) or ids. The response contains `candidates` (each with `score`, `confidence`, `matched` symptoms with weights, `denied`, `not_reported`), `advice` (each with a `because` proof), `next_question` (the best symptom to ask about next, or `null`), `unknown_symptoms`, and a `disclaimer`. Call it repeatedly, adding the answer to `next_question` to `present` or `absent`, to run an interview.

## Limitations

- Hetionet's `DpS` edges are **binary** (a disease is linked to a symptom or not). There are no prevalence figures, so the scorer uses symptom *specificity* rather than likelihood. A frequency-annotated source (e.g. HPO annotations with frequency terms) would allow a proper Bayesian model and is the natural next step.
- Red-flag rules match on symptom **names**. After building the real KB, check that the names in `rules.pl` exist there (MeSH wording can differ from the seed, e.g. for "stiff neck") with `grep` on `data/kb/hetionet_kb.pl`.
- No age, sex, duration or risk-factor modelling.

## License

MIT for the code. Hetionet data is CC0.