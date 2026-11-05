# prolog-dx

A rule-based **symptom → disease diagnostic expert system** in SWI-Prolog, built on a real
biomedical knowledge graph, with explainable answers and a small JSON HTTP API.

> **Educational project only. Not medical advice.** The underlying associations are
> literature co-occurrence, not clinical frequencies.

## Status

Work in progress.

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


