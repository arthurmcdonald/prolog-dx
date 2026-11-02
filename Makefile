SWIPL ?= swipl
PORT  ?= 8080

.PHONY: run

run:
	$(SWIPL) server.pl --port=$(PORT) --kb=data/toy/toy_kb.pl
