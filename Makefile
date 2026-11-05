SWIPL ?= swipl
PORT  ?= 8080

.PHONY: run run-fake data docker

run-fake:
	$(SWIPL) server.pl --port=$(PORT) --kb=data/toy/toy_kb.pl

data: ## download Hetionet files and build data/kb/hetionet_kb.pl
	bash scripts/fetch_data.sh
	python3 scripts/etl_hetionet.py

docker:
	docker build -t prolog-dx .

run: data/kb/hetionet_kb.pl
	$(SWIPL) server.pl --port=$(PORT) --kb=data/kb/hetionet_kb.pl

data/kb/hetionet_kb.pl:
	$(MAKE) data
